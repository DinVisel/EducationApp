using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// Daily attendance for a teacher's class. A student has at most one record per
/// class per day, so marking is a bulk upsert. Scoped to the authenticated
/// teacher's classes.
[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/classrooms/{classroomId:int}/attendance")]
public class AttendanceController : ControllerBase
{
    private readonly AppDbContext _db;

    public AttendanceController(AppDbContext db)
    {
        _db = db;
    }

    private int TeacherId => User.GetTeacherId();

    /// The class roster for a day, each student with their status (or unmarked).
    [HttpGet]
    public async Task<ActionResult<AttendanceDayDto>> GetDay(
        int classroomId, [FromQuery] DateOnly? date)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var day = date ?? DateOnly.FromDateTime(DateTime.UtcNow);

        // Roster ordered by name.
        var roster = await _db.Enrollments
            .AsNoTracking()
            .Where(e => e.ClassroomId == classroomId)
            .Select(e => e.Student!)
            .OrderBy(s => s.FirstName).ThenBy(s => s.LastName)
            .Select(s => new { s.Id, s.FirstName, s.LastName, s.StudentNumber })
            .ToListAsync();

        // Existing marks for the day, keyed by student.
        var marks = await _db.Attendances
            .AsNoTracking()
            .Where(a => a.ClassroomId == classroomId && a.Date == day)
            .ToDictionaryAsync(a => a.StudentId, a => a);

        var students = roster
            .Select(s => new AttendanceStudentDto(
                s.Id, s.FirstName, s.LastName, s.StudentNumber,
                marks.TryGetValue(s.Id, out var m) ? m.Status : null,
                marks.TryGetValue(s.Id, out var n) ? n.Note : null))
            .ToList();

        return Ok(new AttendanceDayDto(day, students));
    }

    /// Bulk-marks (upserts) attendance for the class on one day.
    [HttpPut]
    public async Task<IActionResult> Mark(int classroomId, MarkAttendanceDto dto)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        // Only accept entries for students actually enrolled in this class.
        var enrolledIds = await _db.Enrollments
            .Where(e => e.ClassroomId == classroomId)
            .Select(e => e.StudentId)
            .ToListAsync();
        var enrolled = enrolledIds.ToHashSet();

        var entryIds = dto.Entries.Select(e => e.StudentId).ToList();
        if (entryIds.Any(id => !enrolled.Contains(id)))
            return BadRequest("One or more students are not enrolled in this class.");

        // Existing records for the day, to update in place.
        var existing = await _db.Attendances
            .Where(a => a.ClassroomId == classroomId && a.Date == dto.Date &&
                        entryIds.Contains(a.StudentId))
            .ToDictionaryAsync(a => a.StudentId, a => a);

        var now = DateTime.UtcNow;
        foreach (var entry in dto.Entries)
        {
            if (existing.TryGetValue(entry.StudentId, out var record))
            {
                record.Status = entry.Status;
                record.Note = entry.Note;
                record.TeacherId = TeacherId;
                record.ModifiedAt = now;
            }
            else
            {
                _db.Attendances.Add(new Attendance
                {
                    StudentId = entry.StudentId,
                    ClassroomId = classroomId,
                    Date = dto.Date,
                    Status = entry.Status,
                    Note = entry.Note,
                    TeacherId = TeacherId,
                });
            }
        }

        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// A single student's attendance history in this class, newest first.
    [HttpGet("students/{studentId:int}/history")]
    public async Task<ActionResult<IEnumerable<AttendanceHistoryDto>>> History(
        int classroomId, int studentId, [FromQuery] int? beforeId, [FromQuery] int limit = 30)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var take = Math.Clamp(limit, 1, 100);

        var history = await _db.Attendances
            .AsNoTracking()
            .Where(a => a.ClassroomId == classroomId && a.StudentId == studentId)
            .Where(a => beforeId == null || a.Id < beforeId)
            .OrderByDescending(a => a.Id)
            .Take(take)
            .Select(a => new AttendanceHistoryDto(a.Id, a.Date, a.Status, a.Note))
            .ToListAsync();

        return Ok(history);
    }

    /// Per-student totals + present rate across the class's recorded days.
    [HttpGet("summary")]
    public async Task<ActionResult<IEnumerable<AttendanceSummaryDto>>> Summary(int classroomId)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var roster = await _db.Enrollments
            .AsNoTracking()
            .Where(e => e.ClassroomId == classroomId)
            .Select(e => e.Student!)
            .OrderBy(s => s.FirstName).ThenBy(s => s.LastName)
            .Select(s => new { s.Id, s.FirstName, s.LastName })
            .ToListAsync();

        var records = await _db.Attendances
            .AsNoTracking()
            .Where(a => a.ClassroomId == classroomId)
            .Select(a => new { a.StudentId, a.Status })
            .ToListAsync();

        var byStudent = records
            .GroupBy(r => r.StudentId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var summaries = roster.Select(s =>
        {
            byStudent.TryGetValue(s.Id, out var recs);
            recs ??= new();
            var present = recs.Count(r => r.Status == AttendanceStatus.Present);
            var absent = recs.Count(r => r.Status == AttendanceStatus.Absent);
            var late = recs.Count(r => r.Status == AttendanceStatus.Late);
            var excused = recs.Count(r => r.Status == AttendanceStatus.Excused);
            var total = recs.Count;
            // Present + Late count as "in attendance" for the rate.
            var pct = total == 0 ? 0.0 : Math.Round((present + late) * 100.0 / total, 1);
            return new AttendanceSummaryDto(
                s.Id, s.FirstName, s.LastName,
                present, absent, late, excused, total, pct);
        }).ToList();

        return Ok(summaries);
    }

    private Task<bool> OwnsClassroomAsync(int classroomId) =>
        _db.Classrooms.AnyAsync(c => c.Id == classroomId && c.TeacherId == TeacherId);
}
