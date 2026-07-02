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
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly TokenService _tokens;
    private readonly PasswordHasher<Teacher> _hasher = new();

    public AuthController(AppDbContext db, TokenService tokens)
    {
        _db = db;
        _tokens = tokens;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        if (await _db.Teachers.AnyAsync(t => t.Email == email))
            return Conflict("A teacher with that email already exists.");

        var teacher = new Teacher
        {
            FirstName = dto.FirstName.Trim(),
            LastName = dto.LastName.Trim(),
            Email = email,
        };
        teacher.PasswordHash = _hasher.HashPassword(teacher, dto.Password);

        _db.Teachers.Add(teacher);
        await _db.SaveChangesAsync();

        return Ok(BuildResponse(teacher));
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponseDto>> Login(LoginDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var teacher = await _db.Teachers.FirstOrDefaultAsync(t => t.Email == email);
        if (teacher is null)
            return Unauthorized("Invalid email or password.");

        var result = _hasher.VerifyHashedPassword(teacher, teacher.PasswordHash, dto.Password);
        if (result == PasswordVerificationResult.Failed)
            return Unauthorized("Invalid email or password.");

        // Transparently upgrade the hash if the algorithm parameters changed.
        if (result == PasswordVerificationResult.SuccessRehashNeeded)
        {
            teacher.PasswordHash = _hasher.HashPassword(teacher, dto.Password);
            await _db.SaveChangesAsync();
        }

        return Ok(BuildResponse(teacher));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<TeacherDto>> Me()
    {
        var teacher = await _db.Teachers.FindAsync(User.GetTeacherId());
        return teacher is null ? NotFound() : Ok(ToDto(teacher));
    }

    [Authorize]
    [HttpPut("me")]
    public async Task<ActionResult<TeacherDto>> UpdateMe(UpdateProfileDto dto)
    {
        var teacher = await _db.Teachers.FindAsync(User.GetTeacherId());
        if (teacher is null)
            return NotFound();

        var email = dto.Email.Trim().ToLowerInvariant();
        if (email != teacher.Email &&
            await _db.Teachers.AnyAsync(t => t.Email == email))
            return Conflict("A teacher with that email already exists.");

        teacher.FirstName = dto.FirstName.Trim();
        teacher.LastName = dto.LastName.Trim();
        teacher.Email = email;
        await _db.SaveChangesAsync();

        return Ok(ToDto(teacher));
    }

    private AuthResponseDto BuildResponse(Teacher teacher) =>
        new(_tokens.CreateToken(teacher), ToDto(teacher));

    private static TeacherDto ToDto(Teacher t) =>
        new(t.Id, t.FirstName, t.LastName, t.Email);
}
