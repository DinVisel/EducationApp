using System.Linq.Expressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// The student-facing module: a signed-in student sees their own profile, the
/// classes they're enrolled in, and the assignments fanned out to them, and can
/// mark work done. Everything is scoped to the student id carried in the token.
[ApiController]
[Authorize(Roles = nameof(UserRole.Student))]
[Route("api/student")]
public class StudentModuleController : ControllerBase
{
    private readonly AppDbContext _db;

    public StudentModuleController(AppDbContext db)
    {
        _db = db;
    }

    private int StudentId => User.GetStudentId();

    [HttpGet("me")]
    public async Task<ActionResult<StudentProfileDto>> Me()
    {
        var me = await _db.Students
            .AsNoTracking()
            .Where(s => s.Id == StudentId)
            .Select(s => new StudentProfileDto(
                s.Id, s.FirstName, s.LastName, s.StudentNumber))
            .FirstOrDefaultAsync();

        return me is null ? NotFound() : Ok(me);
    }

    [HttpGet("classes")]
    public async Task<ActionResult<IEnumerable<StudentClassDto>>> Classes()
    {
        var classes = await _db.Enrollments
            .AsNoTracking()
            .Where(e => e.StudentId == StudentId)
            .Select(e => e.Classroom!)
            .OrderBy(c => c.Name)
            .Select(c => new StudentClassDto(
                c.Id,
                c.Name,
                c.Teacher!.FirstName + " " + c.Teacher.LastName))
            .ToListAsync();

        return Ok(classes);
    }

    [HttpGet("assignments")]
    public async Task<ActionResult<IEnumerable<StudentAssignmentDto>>> Assignments()
    {
        var assignments = await _db.StudentAssignments
            .AsNoTracking()
            .Where(sa => sa.StudentId == StudentId)
            .OrderBy(sa => sa.IsDone)
            .ThenBy(sa => sa.Assignment!.DueDate ?? DateOnly.MaxValue)
            .ThenByDescending(sa => sa.Assignment!.CreatedAt)
            .Select(Projection)
            .ToListAsync();

        return Ok(assignments);
    }

    [HttpPost("assignments/{id:int}/complete")]
    public Task<IActionResult> Complete(int id) => SetDone(id, true);

    [HttpPost("assignments/{id:int}/uncomplete")]
    public Task<IActionResult> Uncomplete(int id) => SetDone(id, false);

    // Toggles the student's own copy; `id` is the StudentAssignment id.
    private async Task<IActionResult> SetDone(int id, bool done)
    {
        var sa = await _db.StudentAssignments
            .FirstOrDefaultAsync(x => x.Id == id && x.StudentId == StudentId);
        if (sa is null)
            return NotFound();

        sa.IsDone = done;
        sa.CompletedAt = done ? DateTime.UtcNow : null;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // Translatable projection: the student's copy joined to the class assignment,
    // its class name, and the teacher's attachments.
    private static readonly Expression<Func<StudentAssignment, StudentAssignmentDto>>
        Projection = sa => new StudentAssignmentDto(
            sa.Id,
            sa.AssignmentId,
            sa.Assignment!.Title,
            sa.Assignment.Description,
            sa.Assignment.DueDate,
            sa.Assignment.Classroom!.Name,
            sa.IsDone,
            sa.CompletedAt,
            sa.Assignment.Attachments
                .Select(at => new AssignmentAttachmentDto(
                    at.FileObject!.Id,
                    at.FileObject.FileName,
                    at.FileObject.ContentType,
                    at.FileObject.Size))
                .ToList());
}
