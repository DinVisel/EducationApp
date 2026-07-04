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
    private readonly PasswordHasher<User> _hasher = new();

    public AuthController(AppDbContext db, TokenService tokens)
    {
        _db = db;
        _tokens = tokens;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict("An account with that email already exists.");

        // A teacher account is a User (identity) + a Teacher profile.
        var user = new User { Email = email, Role = UserRole.Teacher };
        user.PasswordHash = _hasher.HashPassword(user, dto.Password);
        user.Teacher = new Teacher
        {
            FirstName = dto.FirstName.Trim(),
            LastName = dto.LastName.Trim(),
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return Ok(BuildResponse(user, user.Teacher));
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponseDto>> Login(LoginDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var user = await _db.Users
            .Include(u => u.Teacher)
            .FirstOrDefaultAsync(u => u.Email == email);
        if (user is null)
            return Unauthorized("Invalid email or password.");

        var result = _hasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
        if (result == PasswordVerificationResult.Failed)
            return Unauthorized("Invalid email or password.");

        // Transparently upgrade the hash if the algorithm parameters changed.
        if (result == PasswordVerificationResult.SuccessRehashNeeded)
        {
            user.PasswordHash = _hasher.HashPassword(user, dto.Password);
            await _db.SaveChangesAsync();
        }

        return Ok(BuildResponse(user, user.Teacher));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<TeacherDto>> Me()
    {
        var teacher = await LoadTeacherAsync();
        return teacher is null ? NotFound() : Ok(ToDto(teacher));
    }

    [Authorize]
    [HttpPut("me")]
    public async Task<ActionResult<TeacherDto>> UpdateMe(UpdateProfileDto dto)
    {
        var teacher = await LoadTeacherAsync();
        if (teacher is null || teacher.User is null)
            return NotFound();

        var email = dto.Email.Trim().ToLowerInvariant();
        if (email != teacher.User.Email &&
            await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict("An account with that email already exists.");

        teacher.FirstName = dto.FirstName.Trim();
        teacher.LastName = dto.LastName.Trim();
        teacher.User.Email = email;
        await _db.SaveChangesAsync();

        return Ok(ToDto(teacher));
    }

    // The teacher profile (with its User) for the signed-in account.
    private Task<Teacher?> LoadTeacherAsync() =>
        _db.Teachers
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Id == User.GetTeacherId());

    private AuthResponseDto BuildResponse(User user, Teacher? teacher) =>
        new(_tokens.CreateToken(user, teacher),
            user.Role.ToString(),
            teacher is null ? null : ToDto(teacher, user));

    private static TeacherDto ToDto(Teacher t) =>
        new(t.Id, t.FirstName, t.LastName, t.User?.Email ?? string.Empty);

    private static TeacherDto ToDto(Teacher t, User u) =>
        new(t.Id, t.FirstName, t.LastName, u.Email);
}
