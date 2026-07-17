using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/students/{studentId:int}/notes")]
public class TrackingNotesController : StudentScopedController
{
    public TrackingNotesController(AppDbContext db) : base(db) { }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TrackingNoteDto>>> GetAll(int studentId)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var notes = await Db.TrackingNotes
            .AsNoTracking()
            .Where(n => n.StudentId == studentId)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => ToDto(n))
            .ToListAsync();

        return Ok(notes);
    }

    [HttpPost]
    public async Task<ActionResult<TrackingNoteDto>> Create(int studentId, CreateTrackingNoteDto dto)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var note = new TrackingNote
        {
            StudentId = studentId,
            Category = dto.Category,
            Content = dto.Content,
            CreatedAt = DateTime.UtcNow
        };

        Db.TrackingNotes.Add(note);
        await Db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), new { studentId }, ToDto(note));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int studentId, int id, UpdateTrackingNoteDto dto)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var note = await Db.TrackingNotes
            .FirstOrDefaultAsync(n => n.Id == id && n.StudentId == studentId);
        if (note is null)
            return NotFound();

        note.Category = dto.Category;
        note.Content = dto.Content;
        await Db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int studentId, int id)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var note = await Db.TrackingNotes
            .FirstOrDefaultAsync(n => n.Id == id && n.StudentId == studentId);
        if (note is null)
            return NotFound();

        Db.TrackingNotes.Remove(note);
        await Db.SaveChangesAsync();
        return NoContent();
    }

    private static TrackingNoteDto ToDto(TrackingNote n) =>
        new(n.Id, n.Category, n.Content, n.CreatedAt, n.StudentId);
}
