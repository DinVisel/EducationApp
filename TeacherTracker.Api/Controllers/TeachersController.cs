using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TeachersController : ControllerBase
{
    private readonly AppDbContext _db;

    public TeachersController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TeacherDto>>> GetAll()
    {
        var teachers = await _db.Teachers
            .AsNoTracking()
            .Select(t => new TeacherDto(t.Id, t.FirstName, t.LastName, t.Email))
            .ToListAsync();

        return Ok(teachers);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<TeacherDto>> GetById(int id)
    {
        var teacher = await _db.Teachers
            .AsNoTracking()
            .Where(t => t.Id == id)
            .Select(t => new TeacherDto(t.Id, t.FirstName, t.LastName, t.Email))
            .FirstOrDefaultAsync();

        return teacher is null ? NotFound() : Ok(teacher);
    }

    [HttpPost]
    public async Task<ActionResult<TeacherDto>> Create(CreateTeacherDto dto)
    {
        var teacher = new Teacher
        {
            FirstName = dto.FirstName,
            LastName = dto.LastName,
            Email = dto.Email
        };

        _db.Teachers.Add(teacher);
        await _db.SaveChangesAsync();

        var result = new TeacherDto(teacher.Id, teacher.FirstName, teacher.LastName, teacher.Email);
        return CreatedAtAction(nameof(GetById), new { id = teacher.Id }, result);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateTeacherDto dto)
    {
        var teacher = await _db.Teachers.FindAsync(id);
        if (teacher is null)
            return NotFound();

        teacher.FirstName = dto.FirstName;
        teacher.LastName = dto.LastName;
        teacher.Email = dto.Email;

        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var teacher = await _db.Teachers.FindAsync(id);
        if (teacher is null)
            return NotFound();

        _db.Teachers.Remove(teacher);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
