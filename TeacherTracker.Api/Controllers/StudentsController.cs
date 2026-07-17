using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/[controller]")]
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly PasswordHasher<User> _hasher = new();

    public StudentsController(AppDbContext db)
    {
        _db = db;
    }

    // All queries are scoped to the authenticated teacher (from the JWT).
    private int TeacherId => User.GetTeacherId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<StudentDto>>> GetAll(
        [FromQuery] int? classroomId, [FromQuery] int? beforeId, [FromQuery] int limit = 20)
    {
        var take = Math.Clamp(limit, 1, 50);

        var query = _db.Students
            .AsNoTracking()
            .Where(s => s.TeacherId == TeacherId)
            .Where(s => beforeId == null || s.Id < beforeId);

        // Optionally restrict to students enrolled in one of the teacher's classes.
        if (classroomId is int cid)
        {
            query = query.Where(s =>
                s.TeacherId == TeacherId &&
                _db.Enrollments.Any(e => e.StudentId == s.Id && e.ClassroomId == cid));
        }

        var students = await query
            .OrderByDescending(s => s.Id)
            .Take(take)
            .Select(s => ToDto(s))
            .ToListAsync();

        return Ok(students);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<StudentDto>> GetById(int id)
    {
        var student = await _db.Students
            .AsNoTracking()
            .Where(s => s.Id == id && s.TeacherId == TeacherId)
            .Select(s => ToDto(s))
            .FirstOrDefaultAsync();

        return student is null ? NotFound() : Ok(student);
    }

    [HttpPost]
    public async Task<ActionResult<StudentDto>> Create(CreateStudentDto dto)
    {
        var student = new Student
        {
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            StudentNumber = dto.StudentNumber,
            DateOfBirth = dto.DateOfBirth,
            Gender = dto.Gender,
            GuardianName = dto.GuardianName,
            GuardianPhone = dto.GuardianPhone,
            Notes = dto.Notes,
            TeacherId = TeacherId
        };

        _db.Students.Add(student);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = student.Id }, ToDto(student));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateStudentDto dto)
    {
        var student = await _db.Students
            .FirstOrDefaultAsync(s => s.Id == id && s.TeacherId == TeacherId);
        if (student is null)
            return NotFound();

        student.FirstName = dto.FirstName;
        student.LastName = dto.LastName;
        student.StudentNumber = dto.StudentNumber;
        student.DateOfBirth = dto.DateOfBirth;
        student.Gender = dto.Gender;
        student.GuardianName = dto.GuardianName;
        student.GuardianPhone = dto.GuardianPhone;
        student.Notes = dto.Notes;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var student = await _db.Students
            .FirstOrDefaultAsync(s => s.Id == id && s.TeacherId == TeacherId);
        if (student is null)
            return NotFound();

        student.IsDeleted = true;
        student.DeletedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // ── Student login accounts (credential provisioning) ────────────────────

    /// Whether this student has a login account, and under which email.
    [HttpGet("{id:int}/account")]
    public async Task<ActionResult<StudentAccountDto>> GetAccount(int id)
    {
        var student = await _db.Students
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id && s.TeacherId == TeacherId);
        if (student is null)
            return NotFound();

        return Ok(student.User is null
            ? new StudentAccountDto(false, null)
            : new StudentAccountDto(true, student.User.Email));
    }

    /// Provisions a login (User with Role=Student) for one of the teacher's
    /// students and links it to the profile.
    [HttpPost("{id:int}/account")]
    public async Task<ActionResult<StudentAccountDto>> CreateAccount(
        int id, CreateStudentAccountDto dto)
    {
        var student = await _db.Students
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id && s.TeacherId == TeacherId);
        if (student is null)
            return NotFound();
        if (student.User is not null)
            return Conflict("This student already has a login account.");

        var email = dto.Email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict("An account with that email already exists.");

        var user = new User { Email = email, Role = UserRole.Student };
        user.PasswordHash = _hasher.HashPassword(user, dto.Password);
        student.User = user;
        await _db.SaveChangesAsync();

        return Ok(new StudentAccountDto(true, email));
    }

    /// Revokes a student's login. The student profile and their work remain.
    [HttpDelete("{id:int}/account")]
    public async Task<IActionResult> DeleteAccount(int id)
    {
        var student = await _db.Students
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.Id == id && s.TeacherId == TeacherId);
        if (student is null || student.User is null)
            return NotFound();

        // Unlink first, then soft-delete the login account (profile/work stays).
        var user = student.User;
        student.User = null;
        student.UserId = null;
        user.IsDeleted = true;
        user.DeletedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private static StudentDto ToDto(Student s) => new(
        s.Id, s.FirstName, s.LastName, s.StudentNumber,
        s.DateOfBirth, s.Gender, s.GuardianName, s.GuardianPhone, s.Notes,
        s.TeacherId);
}
