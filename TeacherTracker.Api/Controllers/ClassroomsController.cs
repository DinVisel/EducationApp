using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiController]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/[controller]")]
public class ClassroomsController : ControllerBase
{
    private readonly AppDbContext _db;

    public ClassroomsController(AppDbContext db)
    {
        _db = db;
    }

    // All queries are scoped to the authenticated teacher (from the JWT).
    private int TeacherId => User.GetTeacherId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ClassroomDto>>> GetAll()
    {
        var classrooms = await _db.Classrooms
            .AsNoTracking()
            .Where(c => c.TeacherId == TeacherId)
            .OrderBy(c => c.Name)
            .Select(c => new ClassroomDto(c.Id, c.Name, c.Enrollments.Count))
            .ToListAsync();

        return Ok(classrooms);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ClassroomDetailDto>> GetById(int id)
    {
        var classroom = await _db.Classrooms
            .AsNoTracking()
            .Where(c => c.Id == id && c.TeacherId == TeacherId)
            .Select(c => new ClassroomDetailDto(
                c.Id,
                c.Name,
                c.Enrollments
                    .Select(e => e.Student!)
                    .OrderBy(s => s.FirstName).ThenBy(s => s.LastName)
                    .Select(s => ToDto(s))
                    .ToList()))
            .FirstOrDefaultAsync();

        return classroom is null ? NotFound() : Ok(classroom);
    }

    [HttpPost]
    public async Task<ActionResult<ClassroomDto>> Create(CreateClassroomDto dto)
    {
        var classroom = new Classroom
        {
            Name = dto.Name.Trim(),
            TeacherId = TeacherId,
        };

        _db.Classrooms.Add(classroom);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = classroom.Id },
            new ClassroomDto(classroom.Id, classroom.Name, 0));
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
        return NoContent();
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
