using System.Linq.Expressions;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// Assignments a teacher publishes to a class. Creating one fans out a
/// per-student copy to every currently enrolled student and attaches any
/// already-uploaded R2 files. Scoped to the authenticated teacher's classes.
[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/classrooms/{classroomId:int}/assignments")]
public class AssignmentsController : ControllerBase
{
    private readonly AppDbContext _db;

    public AssignmentsController(AppDbContext db)
    {
        _db = db;
    }

    private int TeacherId => User.GetTeacherId();
    private int UserId => User.GetUserId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AssignmentDto>>> GetAll(int classroomId)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var assignments = await _db.Assignments
            .AsNoTracking()
            .Where(a => a.ClassroomId == classroomId)
            .OrderByDescending(a => a.CreatedAt)
            .Select(Projection)
            .ToListAsync();

        return Ok(assignments);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<AssignmentDto>> GetById(int classroomId, int id)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var assignment = await _db.Assignments
            .AsNoTracking()
            .Where(a => a.Id == id && a.ClassroomId == classroomId)
            .Select(Projection)
            .FirstOrDefaultAsync();

        return assignment is null ? NotFound() : Ok(assignment);
    }

    [HttpPost]
    public async Task<ActionResult<AssignmentDto>> Create(int classroomId, CreateAssignmentDto dto)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        // Only attach files this teacher owns; silently drop anything else.
        var fileIds = (dto.FileIds ?? new List<int>()).Distinct().ToList();
        var ownedFileIds = fileIds.Count == 0
            ? new List<int>()
            : await _db.Files
                .Where(f => fileIds.Contains(f.Id) && f.OwnerUserId == UserId)
                .Select(f => f.Id)
                .ToListAsync();

        // Fan-out targets: every student currently enrolled in the class.
        var enrolledStudentIds = await _db.Enrollments
            .Where(e => e.ClassroomId == classroomId)
            .Select(e => e.StudentId)
            .ToListAsync();

        var title = dto.Title.Trim();
        var assignment = new Assignment
        {
            Title = title,
            Description = dto.Description,
            DueDate = dto.DueDate,
            ClassroomId = classroomId,
            TeacherId = TeacherId,
            CreatedAt = DateTime.UtcNow,
            Attachments = ownedFileIds
                .Select(fid => new AssignmentAttachment { FileObjectId = fid })
                .ToList(),
            StudentAssignments = enrolledStudentIds
                .Select(sid => new StudentAssignment { StudentId = sid })
                .ToList(),
        };

        _db.Assignments.Add(assignment);

        // Notify every enrolled student who has a login account.
        var recipientUserIds = await _db.Students
            .Where(s => enrolledStudentIds.Contains(s.Id) && s.UserId != null)
            .Select(s => s.UserId!.Value)
            .ToListAsync();
        foreach (var userId in recipientUserIds)
            _db.Notifications.Add(new Notification
            {
                RecipientUserId = userId,
                Type = NotificationType.AssignmentAssigned,
                Text = $"New assignment: {title}",
            });

        await _db.SaveChangesAsync();

        // Reload with attachment file metadata for the response.
        var created = await _db.Assignments
            .AsNoTracking()
            .Where(a => a.Id == assignment.Id)
            .Select(Projection)
            .FirstAsync();

        return CreatedAtAction(nameof(GetById),
            new { classroomId, id = assignment.Id }, created);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int classroomId, int id)
    {
        var assignment = await _db.Assignments
            .FirstOrDefaultAsync(a =>
                a.Id == id && a.ClassroomId == classroomId && a.TeacherId == TeacherId);
        if (assignment is null)
            return NotFound();

        _db.Assignments.Remove(assignment);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private Task<bool> OwnsClassroomAsync(int classroomId) =>
        _db.Classrooms.AnyAsync(c => c.Id == classroomId && c.TeacherId == TeacherId);

    // Reused across queries; kept as an Expression so EF translates the
    // fan-out counts and attachment join to SQL (a plain method would be
    // evaluated client-side against unloaded navigations).
    private static readonly Expression<Func<Assignment, AssignmentDto>> Projection = a =>
        new AssignmentDto(
            a.Id,
            a.Title,
            a.Description,
            a.DueDate,
            a.CreatedAt,
            a.ClassroomId,
            a.StudentAssignments.Count,
            a.StudentAssignments.Count(sa => sa.IsDone),
            a.Attachments
                .Select(at => new AssignmentAttachmentDto(
                    at.FileObject!.Id,
                    at.FileObject.FileName,
                    at.FileObject.ContentType,
                    at.FileObject.Size))
                .ToList());
}
