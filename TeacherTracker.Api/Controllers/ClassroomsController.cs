using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Notifications;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Caching;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/[controller]")]
public class ClassroomsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ApiResponseCache _cache;
    private readonly INotificationPublisher _publisher;
    private readonly PasswordHasher<User> _hasher = new();

    public ClassroomsController(
        AppDbContext db, ApiResponseCache cache, INotificationPublisher publisher)
    {
        _db = db;
        _cache = cache;
        _publisher = publisher;
    }

    // All queries are scoped to the authenticated teacher (from the JWT).
    private int TeacherId => User.GetTeacherId();

    // Roster cache key — teacher-scoped so it can never leak across accounts.
    private string RosterKey(int classroomId) => $"roster:{TeacherId}:{classroomId}";

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ClassroomDto>>> GetAll(
        [FromQuery] int? beforeId, [FromQuery] int limit = 20)
    {
        var take = Math.Clamp(limit, 1, 50);

        var classrooms = await _db.Classrooms
            .AsNoTracking()
            .Where(c => c.TeacherId == TeacherId)
            .Where(c => beforeId == null || c.Id < beforeId)
            .OrderByDescending(c => c.Id)
            .Take(take)
            .Select(c => new ClassroomDto(c.Id, c.Name, c.ClassCode, c.Enrollments.Count))
            .ToListAsync();

        return Ok(classrooms);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ClassroomDetailDto>> GetById(int id)
    {
        // Serve a cached roster (with ETag/304) when warm. Invalidated on
        // enroll/unenroll/rename/delete below; a short TTL also bounds staleness
        // from cross-controller edits (e.g. a student's name changing).
        var key = RosterKey(id);
        var cached = _cache.Get(key);
        if (cached is not null)
            return this.Cached(cached);

        var classroom = await _db.Classrooms
            .AsNoTracking()
            .Where(c => c.Id == id && c.TeacherId == TeacherId)
            .Select(c => new ClassroomDetailDto(
                c.Id,
                c.Name,
                c.ClassCode,
                c.Enrollments
                    .Select(e => e.Student!)
                    .OrderBy(s => s.FirstName).ThenBy(s => s.LastName)
                    .Select(s => ToDto(s))
                    .ToList()))
            .FirstOrDefaultAsync();

        if (classroom is null)
            return NotFound();

        return this.Cached(_cache.Set(key, classroom, TimeSpan.FromSeconds(30)));
    }

    [HttpPost]
    public async Task<ActionResult<ClassroomDto>> Create(CreateClassroomDto dto)
    {
        var classroom = new Classroom
        {
            Name = dto.Name.Trim(),
            TeacherId = TeacherId,
            ClassCode = await GenerateUniqueClassCodeAsync(),
        };

        _db.Classrooms.Add(classroom);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = classroom.Id },
            new ClassroomDto(classroom.Id, classroom.Name, classroom.ClassCode, 0));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateClassroomDto dto)
    {
        var classroom = await _db.Classrooms
            .FirstOrDefaultAsync(c => c.Id == id && c.TeacherId == TeacherId);
        if (classroom is null)
            return NotFound();

        classroom.Name = dto.Name.Trim();
        await _db.SaveChangesAsync();
        _cache.Remove(RosterKey(id));
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var classroom = await _db.Classrooms
            .FirstOrDefaultAsync(c => c.Id == id && c.TeacherId == TeacherId);
        if (classroom is null)
            return NotFound();

        _db.Classrooms.Remove(classroom);
        await _db.SaveChangesAsync();
        _cache.Remove(RosterKey(id));
        return NoContent();
    }

    [HttpPost("{id:int}/students/{studentId:int}")]
    public async Task<IActionResult> Enroll(int id, int studentId)
    {
        if (!await OwnsClassroomAsync(id) || !await OwnsStudentAsync(studentId))
            return NotFound();

        var already = await _db.Enrollments
            .AnyAsync(e => e.ClassroomId == id && e.StudentId == studentId);
        if (already)
            return NoContent();

        _db.Enrollments.Add(new Enrollment { ClassroomId = id, StudentId = studentId });
        await _db.SaveChangesAsync();
        _cache.Remove(RosterKey(id));
        return NoContent();
    }

    [HttpDelete("{id:int}/students/{studentId:int}")]
    public async Task<IActionResult> Unenroll(int id, int studentId)
    {
        if (!await OwnsClassroomAsync(id))
            return NotFound();

        var enrollment = await _db.Enrollments
            .FirstOrDefaultAsync(e => e.ClassroomId == id && e.StudentId == studentId);
        if (enrollment is null)
            return NotFound();

        _db.Enrollments.Remove(enrollment);
        await _db.SaveChangesAsync();
        _cache.Remove(RosterKey(id));
        return NoContent();
    }

    // ── Method A: Access Card provisioning (ages 8-10) ──────────────────────

    /// Bulk-provisions access-card students from a pasted list of names. Each name
    /// becomes a Student (RegistrationType=AccessCard) + a passwordless login
    /// (User with an AccessCode + hashed QR secret) + an Enrollment in this class —
    /// immediate access, no lobby. Returns each card's typed code and raw QR token
    /// (shown once) for printing.
    [HttpPost("{id:int}/access-cards")]
    public async Task<ActionResult<IEnumerable<AccessCardDto>>> CreateAccessCards(
        int id, CreateAccessCardsDto dto)
    {
        if (!await OwnsClassroomAsync(id))
            return NotFound();

        // Clean the pasted list: trim, drop blanks, cap the batch.
        var names = dto.Names
            .Select(n => n?.Trim() ?? string.Empty)
            .Where(n => n.Length > 0)
            .Take(100)
            .ToList();
        if (names.Count == 0)
            return BadRequest("Provide at least one non-empty name.");

        // Build each Student + its passwordless login + its enrollment via nav
        // properties, tracking (student, code, rawQr) so we can read back the
        // generated ids after SaveChanges.
        var provisioned = new List<(Student Student, string Code, string Qr)>(names.Count);
        foreach (var fullName in names)
        {
            var (first, last) = SplitName(fullName);
            var accessCode = await GenerateUniqueAccessCodeAsync();
            var qrToken = CodeGenerator.QrSecret();

            var student = new Student
            {
                FirstName = first,
                LastName = last,
                TeacherId = TeacherId,
                RegistrationType = StudentRegistrationType.AccessCard,
                User = new User
                {
                    Role = UserRole.Student,
                    AccessCode = accessCode,
                    AccessQrTokenHash = TokenService.HashToken(qrToken),
                },
            };
            _db.Students.Add(student);
            // Enroll immediately (teacher-provisioned → no lobby). The Student nav
            // lets EF fix up StudentId once the student is inserted.
            _db.Enrollments.Add(new Enrollment { ClassroomId = id, Student = student });

            provisioned.Add((student, accessCode, qrToken));
        }

        await _db.SaveChangesAsync();

        var cards = provisioned
            .Select(p => new AccessCardDto(
                p.Student.Id, p.Student.FirstName, p.Student.LastName, p.Code, p.Qr))
            .ToList();

        _cache.Remove(RosterKey(id));
        return Ok(cards);
    }

    /// Lists the access cards (typed codes) for a class, for reprinting. The QR
    /// secret is never returned here — it's write-once; rotate to get a fresh one.
    [HttpGet("{id:int}/access-cards")]
    public async Task<ActionResult<IEnumerable<AccessCardDto>>> GetAccessCards(int id)
    {
        if (!await OwnsClassroomAsync(id))
            return NotFound();

        var cards = await _db.Enrollments
            .AsNoTracking()
            .Where(e => e.ClassroomId == id &&
                        e.Student!.RegistrationType == StudentRegistrationType.AccessCard &&
                        e.Student.User != null)
            .Select(e => new AccessCardDto(
                e.Student!.Id, e.Student.FirstName, e.Student.LastName,
                e.Student.User!.AccessCode!, null))
            .ToListAsync();

        return Ok(cards);
    }

    /// Rotates one access-card student's code + QR (e.g. a lost card). Returns the
    /// new code and raw QR token (shown once).
    [HttpPost("{id:int}/access-cards/{studentId:int}/rotate")]
    public async Task<ActionResult<AccessCardDto>> RotateAccessCard(int id, int studentId)
    {
        var student = await _db.Students
            .Include(s => s.User)
            .FirstOrDefaultAsync(s =>
                s.Id == studentId && s.TeacherId == TeacherId &&
                s.RegistrationType == StudentRegistrationType.AccessCard);
        if (student is null || student.User is null)
            return NotFound();
        if (!await _db.Enrollments.AnyAsync(e => e.ClassroomId == id && e.StudentId == studentId))
            return NotFound();

        var accessCode = await GenerateUniqueAccessCodeAsync();
        var qrToken = CodeGenerator.QrSecret();
        student.User.AccessCode = accessCode;
        student.User.AccessQrTokenHash = TokenService.HashToken(qrToken);
        await _db.SaveChangesAsync();

        return Ok(new AccessCardDto(
            student.Id, student.FirstName, student.LastName, accessCode, qrToken));
    }

    // ── Method B: Waiting Lobby (teacher side) ──────────────────────────────

    /// The class's pending join requests (the lobby) awaiting a decision.
    [HttpGet("{id:int}/join-requests")]
    public async Task<ActionResult<IEnumerable<LobbyEntryDto>>> GetJoinRequests(int id)
    {
        if (!await OwnsClassroomAsync(id))
            return NotFound();

        var entries = await _db.ClassJoinRequests
            .AsNoTracking()
            .Where(r => r.ClassroomId == id && r.Status == ClassJoinRequestStatus.Pending)
            .OrderBy(r => r.CreatedAt)
            .Select(r => new LobbyEntryDto(
                r.Id, r.StudentId, r.Student!.FirstName, r.Student.LastName,
                r.Student.User!.Email, r.CreatedAt))
            .ToListAsync();

        return Ok(entries);
    }

    /// Approves a pending request: creates the Enrollment (full membership) and
    /// notifies the student.
    [HttpPost("{id:int}/join-requests/{requestId:int}/approve")]
    public async Task<IActionResult> ApproveJoinRequest(int id, int requestId)
    {
        var request = await LoadPendingRequestAsync(id, requestId);
        if (request is null)
            return NotFound();

        request.Status = ClassJoinRequestStatus.Approved;
        request.DecidedAt = DateTime.UtcNow;
        request.DecidedByTeacherId = TeacherId;

        // Create membership if it doesn't somehow already exist.
        var already = await _db.Enrollments
            .AnyAsync(e => e.ClassroomId == id && e.StudentId == request.StudentId);
        if (!already)
            _db.Enrollments.Add(new Enrollment { ClassroomId = id, StudentId = request.StudentId });

        var recipient = await QueueDecisionNotificationAsync(
            request, NotificationType.ClassJoinApproved, "approved");
        await _db.SaveChangesAsync();
        if (recipient is int userId)
            await _publisher.NotifyAsync(new[] { userId });
        _cache.Remove(RosterKey(id));
        return NoContent();
    }

    /// Rejects a pending request. No enrollment is created; the row is kept as a
    /// record and the student is notified.
    [HttpPost("{id:int}/join-requests/{requestId:int}/reject")]
    public async Task<IActionResult> RejectJoinRequest(int id, int requestId)
    {
        var request = await LoadPendingRequestAsync(id, requestId);
        if (request is null)
            return NotFound();

        request.Status = ClassJoinRequestStatus.Rejected;
        request.DecidedAt = DateTime.UtcNow;
        request.DecidedByTeacherId = TeacherId;

        var recipient = await QueueDecisionNotificationAsync(
            request, NotificationType.ClassJoinRejected, "rejected");
        await _db.SaveChangesAsync();
        if (recipient is int userId)
            await _publisher.NotifyAsync(new[] { userId });
        return NoContent();
    }

    private async Task<ClassJoinRequest?> LoadPendingRequestAsync(int classroomId, int requestId)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return null;
        return await _db.ClassJoinRequests
            .Include(r => r.Student)
            .FirstOrDefaultAsync(r =>
                r.Id == requestId && r.ClassroomId == classroomId &&
                r.Status == ClassJoinRequestStatus.Pending);
    }

    // Queues the decision notification for the requesting student (if they have a
    // login) and returns their user id so the caller can publish after saving.
    private async Task<int?> QueueDecisionNotificationAsync(
        ClassJoinRequest request, NotificationType type, string verb)
    {
        var recipientUserId = request.Student?.UserId;
        if (recipientUserId is not int userId)
            return null;

        var className = await _db.Classrooms
            .Where(c => c.Id == request.ClassroomId)
            .Select(c => c.Name)
            .FirstOrDefaultAsync() ?? "the class";

        _db.Notifications.Add(new Notification
        {
            RecipientUserId = userId,
            Type = type,
            Text = $"Your request to join {className} was {verb}.",
        });
        return userId;
    }

    // Retries until it finds an access code not already in use.
    private async Task<string> GenerateUniqueAccessCodeAsync()
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = CodeGenerator.ShortCode(6);
            if (!await _db.Users.IgnoreQueryFilters().AnyAsync(u => u.AccessCode == code))
                return code;
        }
        throw new InvalidOperationException("Could not generate a unique access code.");
    }

    // Retries until it finds a class code not already in use.
    private async Task<string> GenerateUniqueClassCodeAsync()
    {
        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = CodeGenerator.ShortCode(6);
            if (!await _db.Classrooms.AnyAsync(c => c.ClassCode == code))
                return code;
        }
        throw new InvalidOperationException("Could not generate a unique class code.");
    }

    private static (string First, string Last) SplitName(string fullName)
    {
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0)
            return (fullName, string.Empty);
        if (parts.Length == 1)
            return (parts[0], string.Empty);
        return (string.Join(' ', parts[..^1]), parts[^1]);
    }

    private Task<bool> OwnsClassroomAsync(int classroomId) =>
        _db.Classrooms.AnyAsync(c => c.Id == classroomId && c.TeacherId == TeacherId);

    private Task<bool> OwnsStudentAsync(int studentId) =>
        _db.Students.AnyAsync(s => s.Id == studentId && s.TeacherId == TeacherId);

    private static StudentDto ToDto(Student s) => new(
        s.Id, s.FirstName, s.LastName, s.StudentNumber,
        s.DateOfBirth, s.Gender, s.GuardianName, s.GuardianPhone, s.Notes,
        s.TeacherId);
}
