using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiController]
[Authorize]
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
    public async Task<ActionResult<IEnumerable<StudentDto>>> GetAll()
    {
        var students = await _db.Students
            .AsNoTracking()
            .Where(s => s.TeacherId == TeacherId)
            .Select(s => new StudentDto(s.Id, s.FirstName, s.LastName, s.StudentNumber, s.TeacherId))
            .ToListAsync();

        return Ok(students);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<StudentDto>> GetById(int id)
    {
        var student = await _db.Students
            .AsNoTracking()
            .Where(s => s.Id == id && s.TeacherId == TeacherId)
            .Select(s => new StudentDto(s.Id, s.FirstName, s.LastName, s.StudentNumber, s.TeacherId))
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
            TeacherId = TeacherId
        };

        _db.Students.Add(student);
        await _db.SaveChangesAsync();

        var result = new StudentDto(student.Id, student.FirstName, student.LastName, student.StudentNumber, student.TeacherId);
        return CreatedAtAction(nameof(GetById), new { id = student.Id }, result);
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
}
