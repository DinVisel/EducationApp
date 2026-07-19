using System.Security.Cryptography;
using Asp.Versioning;
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
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
public class AuthController : ControllerBase
{
    private const int ResetTokenExpiryMinutes = 45;

    private readonly AppDbContext _db;
    private readonly TokenService _tokens;
    private readonly IEmailService _email;
    private readonly SocialTokenVerifier _social;
    private readonly PasswordHasher<User> _hasher = new();

    public AuthController(
        AppDbContext db, TokenService tokens, IEmailService email, SocialTokenVerifier social)
    {
        _db = db;
        _tokens = tokens;
        _email = email;
        _social = social;
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

        return Ok(await IssueAsync(user, teacher, null));
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

        return Ok(await IssueAsync(user, user.Teacher, user.Student));
    }

    [EnableRateLimiting("auth")]
    [HttpPost("google")]
    public async Task<ActionResult<AuthResponseDto>> Google(SocialLoginDto dto)
    {
        SocialIdentity identity;
        try
        {
            identity = await _social.VerifyGoogleAsync(dto.IdToken);
        }
        catch
        {
            return Unauthorized("Could not verify the Google sign-in.");
        }

        return await SocialSignInAsync(SocialProvider.Google, identity);
    }

    [EnableRateLimiting("auth")]
    [HttpPost("apple")]
    public async Task<ActionResult<AuthResponseDto>> Apple(SocialLoginDto dto)
    {
        SocialIdentity identity;
        try
        {
            identity = await _social.VerifyAppleAsync(
                dto.IdToken, dto.Nonce, dto.FirstName, dto.LastName);
        }
        catch
        {
            return Unauthorized("Could not verify the Apple sign-in.");
        }

        return await SocialSignInAsync(SocialProvider.Apple, identity);
    }

    private enum SocialProvider { Google, Apple }

    // Shared social sign-in: match the account by provider subject, else link by
    // verified email, else create a new Teacher account (never Admin). Issues our
    // own token pair, so everything downstream is identical to password login.
    private async Task<ActionResult<AuthResponseDto>> SocialSignInAsync(
        SocialProvider provider, SocialIdentity identity)
    {
        // 1. Returning user: match on the provider's stable subject id.
        System.Linq.Expressions.Expression<Func<User, bool>> bySubject =
            provider == SocialProvider.Google
                ? u => u.GoogleSubject == identity.Subject
                : u => u.AppleSubject == identity.Subject;
        var user = await _db.Users
            .Include(u => u.Teacher)
            .Include(u => u.Student)
            .FirstOrDefaultAsync(bySubject);

        if (user is not null)
            return Ok(await IssueAsync(user, user.Teacher, user.Student));

        var email = identity.Email?.Trim().ToLowerInvariant();

        // 2. Existing account with the same verified email: link this provider.
        if (!string.IsNullOrEmpty(email))
        {
            user = await _db.Users
                .Include(u => u.Teacher)
                .Include(u => u.Student)
                .FirstOrDefaultAsync(u => u.Email == email);
            if (user is not null)
            {
                LinkSubject(user, provider, identity.Subject);
                await _db.SaveChangesAsync();
                return Ok(await IssueAsync(user, user.Teacher, user.Student));
            }
        }

        // 3. New account. A verified email is required so we can key/link it.
        if (string.IsNullOrEmpty(email))
            return BadRequest("A verified email is required to create an account.");

        var teacher = new Teacher
        {
            FirstName = identity.FirstName?.Trim() ?? string.Empty,
            LastName = identity.LastName?.Trim() ?? string.Empty,
        };
        // No password login until the account sets one via forgot/reset-password.
        var newUser = new User { Email = email, Role = UserRole.Teacher, Teacher = teacher };
        LinkSubject(newUser, provider, identity.Subject);

        _db.Users.Add(newUser);
        await _db.SaveChangesAsync();

        return Ok(await IssueAsync(newUser, teacher, null));
    }

    private static void LinkSubject(User user, SocialProvider provider, string subject)
    {
        if (provider == SocialProvider.Google) user.GoogleSubject = subject;
        else user.AppleSubject = subject;
    }

    [EnableRateLimiting("auth")]
    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponseDto>> Refresh(RefreshRequestDto dto)
    {
        var hash = TokenService.HashToken(dto.RefreshToken);
        var token = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.TokenHash == hash);
        if (token is null)
            return Unauthorized("Invalid refresh token.");

        if (!token.IsActive)
        {
            // A revoked token presented again suggests theft/replay: defensively
            // revoke every still-active token for the account.
            if (token.RevokedAtUtc is not null)
                await _db.RefreshTokens
                    .Where(t => t.UserId == token.UserId && t.RevokedAtUtc == null)
                    .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAtUtc, DateTime.UtcNow));
            return Unauthorized("Refresh token is no longer valid.");
        }

        var user = await _db.Users
            .Include(u => u.Teacher)
            .Include(u => u.Student)
            .FirstOrDefaultAsync(u => u.Id == token.UserId);
        if (user is null)
            return Unauthorized("Invalid refresh token.");

        // Rotate: revoke the presented token and issue a fresh pair.
        var (rawRefresh, refreshEntity) = _tokens.CreateRefreshToken(user.Id);
        token.RevokedAtUtc = DateTime.UtcNow;
        token.ReplacedByTokenHash = refreshEntity.TokenHash;
        _db.RefreshTokens.Add(refreshEntity);
        await _db.SaveChangesAsync();

        return Ok(new AuthResponseDto(
            _tokens.CreateToken(user, user.Teacher, user.Student),
            rawRefresh,
            _tokens.AccessTokenExpiresAtUtc,
            user.Role.ToString(),
            user.Teacher is null ? null : ToDto(user.Teacher, user),
            user.Student is null ? null : ToProfileDto(user.Student),
            user.MustChangePassword));
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(LogoutRequestDto dto)
    {
        var hash = TokenService.HashToken(dto.RefreshToken);
        var token = await _db.RefreshTokens
            .FirstOrDefaultAsync(t => t.TokenHash == hash && t.UserId == User.GetUserId());
        if (token is not null && token.RevokedAtUtc is null)
        {
            token.RevokedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }

        return NoContent();
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
            user.PasswordResetTokenHash = TokenService.HashToken(rawToken);
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
        var tokenHash = TokenService.HashToken(dto.Token);
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

    /// Lets a signed-in account (any role) change its own password by proving the
    /// current one. Clears the first-login `MustChangePassword` gate, ends the
    /// account's *other* sessions (revokes their refresh tokens), and returns a
    /// fresh token pair so the current session stays signed in.
    [Authorize]
    [EnableRateLimiting("auth")]
    [HttpPost("change-password")]
    public async Task<ActionResult<AuthResponseDto>> ChangePassword(ChangePasswordDto dto)
    {
        var user = await _db.Users
            .Include(u => u.Teacher)
            .Include(u => u.Student)
            .FirstOrDefaultAsync(u => u.Id == User.GetUserId());
        if (user is null)
            return Unauthorized();

        var check = _hasher.VerifyHashedPassword(user, user.PasswordHash, dto.CurrentPassword);
        if (check == PasswordVerificationResult.Failed)
            return BadRequest("Your current password is incorrect.");

        user.PasswordHash = _hasher.HashPassword(user, dto.NewPassword);
        user.MustChangePassword = false;

        // A password change ends every existing session; IssueAsync then mints a
        // new pair for this one.
        await _db.RefreshTokens
            .Where(t => t.UserId == user.Id && t.RevokedAtUtc == null)
            .ExecuteUpdateAsync(s => s.SetProperty(t => t.RevokedAtUtc, DateTime.UtcNow));

        return Ok(await IssueAsync(user, user.Teacher, user.Student));
    }

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
            user.Student is null ? null : ToProfileDto(user.Student),
            user.MustChangePassword));
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

    // Issues an access token + a fresh (persisted) refresh token for the account,
    // building the profile DTO from whichever role the user has.
    private async Task<AuthResponseDto> IssueAsync(User user, Teacher? teacher, Student? student)
    {
        var (rawRefresh, refreshEntity) = _tokens.CreateRefreshToken(user.Id);
        _db.RefreshTokens.Add(refreshEntity);
        await _db.SaveChangesAsync();

        return new AuthResponseDto(
            _tokens.CreateToken(user, teacher, student),
            rawRefresh,
            _tokens.AccessTokenExpiresAtUtc,
            user.Role.ToString(),
            teacher is null ? null : ToDto(teacher, user),
            student is null ? null : ToProfileDto(student),
            user.MustChangePassword);
    }

    private static TeacherDto ToDto(Teacher t) =>
        new(t.Id, t.UserId, t.FirstName, t.LastName, t.User?.Email ?? string.Empty,
            t.AvatarFileObjectId, t.CoverFileObjectId);

    private static TeacherDto ToDto(Teacher t, User u) =>
        new(t.Id, u.Id, t.FirstName, t.LastName, u.Email,
            t.AvatarFileObjectId, t.CoverFileObjectId);

    private static StudentProfileDto ToProfileDto(Student s) =>
        new(s.Id, s.FirstName, s.LastName, s.StudentNumber);
}
