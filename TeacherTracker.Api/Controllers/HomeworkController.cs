using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/students/{studentId:int}/homework")]
public class HomeworkController : StudentScopedController
{
    public HomeworkController(AppDbContext db) : base(db) { }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<HomeworkDto>>> GetAll(
        int studentId, [FromQuery] int? beforeId, [FromQuery] int limit = 20)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var take = Math.Clamp(limit, 1, 50);

        var items = await Db.Homeworks
            .AsNoTracking()
            .Where(h => h.StudentId == studentId)
            .Where(h => beforeId == null || h.Id < beforeId)
            .OrderByDescending(h => h.Id)
            .Take(take)
            .Select(h => ToDto(h))
            .ToListAsync();

        return Ok(items);
    }

    [HttpPost]
    public async Task<ActionResult<HomeworkDto>> Create(int studentId, CreateHomeworkDto dto)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var homework = new Homework
        {
            StudentId = studentId,
            Title = dto.Title,
            Description = dto.Description,
            DueDate = dto.DueDate,
            IsDone = dto.IsDone,
            CreatedAt = DateTime.UtcNow
        };

        Db.Homeworks.Add(homework);
        await Db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), new { studentId }, ToDto(homework));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int studentId, int id, UpdateHomeworkDto dto)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var homework = await Db.Homeworks
            .FirstOrDefaultAsync(h => h.Id == id && h.StudentId == studentId);
        if (homework is null)
            return NotFound();

        homework.Title = dto.Title;
        homework.Description = dto.Description;
        homework.DueDate = dto.DueDate;
        homework.IsDone = dto.IsDone;
        await Db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int studentId, int id)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var homework = await Db.Homeworks
            .FirstOrDefaultAsync(h => h.Id == id && h.StudentId == studentId);
        if (homework is null)
            return NotFound();

        Db.Homeworks.Remove(homework);
        await Db.SaveChangesAsync();
        return NoContent();
    }

    private static HomeworkDto ToDto(Homework h) =>
        new(h.Id, h.Title, h.Description, h.DueDate, h.IsDone, h.CreatedAt, h.StudentId);
}
