using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Email;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private const int ResetTokenExpiryMinutes = 45;

    private readonly AppDbContext _db;
    private readonly TokenService _tokens;
    private readonly IEmailService _email;
    private readonly PasswordHasher<User> _hasher = new();

    public AuthController(AppDbContext db, TokenService tokens, IEmailService email)
    {
        _db = db;
        _tokens = tokens;
        _email = email;
    }

    [EnableRateLimiting("auth")]
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict("An account with that email already exists.");

        // A teacher account is a User (identity) + a Teacher profile.
        var teacher = new Teacher
        {
            FirstName = dto.FirstName.Trim(),
            LastName = dto.LastName.Trim(),
        };
        var user = new User { Email = email, Role = UserRole.Teacher, Teacher = teacher };
        user.PasswordHash = _hasher.HashPassword(user, dto.Password);

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return Ok(BuildResponse(user, teacher));
    }

    [EnableRateLimiting("auth")]
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponseDto>> Login(LoginDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var user = await _db.Users
            .Include(u => u.Teacher)
            .Include(u => u.Student)
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

        return Ok(BuildResponse(user));
    }

    [EnableRateLimiting("auth")]
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user is not null)
        {
            var rawToken = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
            user.PasswordResetTokenHash = HashToken(rawToken);
            user.PasswordResetTokenExpiresAtUtc = DateTime.UtcNow.AddMinutes(ResetTokenExpiryMinutes);
            await _db.SaveChangesAsync();

            await _email.SendAsync(user.Email, "Reset your password",
                $"Use this code to reset your password: {rawToken}\n" +
                $"This code expires in {ResetTokenExpiryMinutes} minutes.");
        }

        // Always 200, whether or not the account exists, so callers can't probe
        // which emails are registered.
        return Ok();
    }

    [EnableRateLimiting("auth")]
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(ResetPasswordDto dto)
    {
        var tokenHash = HashToken(dto.Token);
        var user = await _db.Users.FirstOrDefaultAsync(u =>
            u.PasswordResetTokenHash == tokenHash &&
            u.PasswordResetTokenExpiresAtUtc != null &&
            u.PasswordResetTokenExpiresAtUtc > DateTime.UtcNow);
        if (user is null)
            return BadRequest("This reset code is invalid or has expired.");

        user.PasswordHash = _hasher.HashPassword(user, dto.NewPassword);
        user.PasswordResetTokenHash = null;
        user.PasswordResetTokenExpiresAtUtc = null;
        await _db.SaveChangesAsync();

        return Ok();
    }

    private static string HashToken(string rawToken) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(rawToken)));

    /// The current identity (any role), used to restore a session from a saved
    /// token at startup. Returns the profile matching the account's role.
    [Authorize]
    [HttpGet("session")]
    public async Task<ActionResult<SessionDto>> Session()
    {
        var user = await _db.Users
            .Include(u => u.Teacher)
            .Include(u => u.Student)
            .FirstOrDefaultAsync(u => u.Id == User.GetUserId());
        if (user is null)
            return Unauthorized();

        return Ok(new SessionDto(
            user.Role.ToString(),
            user.Teacher is null ? null : ToDto(user.Teacher, user),
            user.Student is null ? null : ToProfileDto(user.Student)));
    }

    [Authorize(Roles = nameof(UserRole.Teacher))]
    [HttpGet("me")]
    public async Task<ActionResult<TeacherDto>> Me()
    {
        var teacher = await LoadTeacherAsync();
        return teacher is null ? NotFound() : Ok(ToDto(teacher));
    }

    [Authorize(Roles = nameof(UserRole.Teacher))]
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

        // Profile images must be files this teacher uploaded.
        if (dto.AvatarFileId is int avatarId)
        {
            if (!await _db.Files.AnyAsync(f => f.Id == avatarId && f.OwnerUserId == teacher.UserId))
                return BadRequest("Avatar file not found or not owned by you.");
            teacher.AvatarFileObjectId = avatarId;
        }
        if (dto.CoverFileId is int coverId)
        {
            if (!await _db.Files.AnyAsync(f => f.Id == coverId && f.OwnerUserId == teacher.UserId))
                return BadRequest("Cover file not found or not owned by you.");
            teacher.CoverFileObjectId = coverId;
        }

        await _db.SaveChangesAsync();

        return Ok(ToDto(teacher));
    }

    // The teacher profile (with its User) for the signed-in account.
    private Task<Teacher?> LoadTeacherAsync() =>
        _db.Teachers
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Id == User.GetTeacherId());

    // Register only ever produces a teacher, so keep the explicit overload for it.
    private AuthResponseDto BuildResponse(User user, Teacher teacher) =>
        new(_tokens.CreateToken(user, teacher),
            user.Role.ToString(),
            ToDto(teacher, user));

    // Login builds from whichever profile the user has (teacher or student).
    private AuthResponseDto BuildResponse(User user) =>
        new(_tokens.CreateToken(user, user.Teacher, user.Student),
            user.Role.ToString(),
            user.Teacher is null ? null : ToDto(user.Teacher, user),
            user.Student is null ? null : ToProfileDto(user.Student));

    private static TeacherDto ToDto(Teacher t) =>
        new(t.Id, t.UserId, t.FirstName, t.LastName, t.User?.Email ?? string.Empty,
            t.AvatarFileObjectId, t.CoverFileObjectId);

    private static TeacherDto ToDto(Teacher t, User u) =>
        new(t.Id, u.Id, t.FirstName, t.LastName, u.Email,
            t.AvatarFileObjectId, t.CoverFileObjectId);

    private static StudentProfileDto ToProfileDto(Student s) =>
        new(s.Id, s.FirstName, s.LastName, s.StudentNumber);
}
