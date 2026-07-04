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
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _db;

    public StudentsController(AppDbContext db)
    {
        _db = db;
    }

    // All queries are scoped to the authenticated teacher (from the JWT).
    private int TeacherId => User.GetTeacherId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<StudentDto>>> GetAll(
        [FromQuery] int? classroomId)
    {
        var query = _db.Students
            .AsNoTracking()
            .Where(s => s.TeacherId == TeacherId);

        // Optionally restrict to students enrolled in one of the teacher's classes.
        if (classroomId is int cid)
        {
            query = query.Where(s =>
                s.TeacherId == TeacherId &&
                _db.Enrollments.Any(e => e.StudentId == s.Id && e.ClassroomId == cid));
        }

        var students = await query
            .OrderBy(s => s.FirstName).ThenBy(s => s.LastName)
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

        _db.Students.Remove(student);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private static StudentDto ToDto(Student s) => new(
        s.Id, s.FirstName, s.LastName, s.StudentNumber,
        s.DateOfBirth, s.Gender, s.GuardianName, s.GuardianPhone, s.Notes,
        s.TeacherId);
}
