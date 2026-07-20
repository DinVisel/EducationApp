using System.Security.Cryptography;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
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
    private readonly AdminOptions _admin;
    private readonly PasswordHasher<User> _hasher = new();

    public AuthController(
        AppDbContext db, TokenService tokens, IEmailService email,
        SocialTokenVerifier social, IOptions<AdminOptions> admin)
    {
        _db = db;
        _tokens = tokens;
        _email = email;
        _social = social;
        _admin = admin.Value;
    }

    [EnableRateLimiting("auth")]
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto dto)
    {
        var email = dto.Email.Trim().ToLowerInvariant();
        if (await _db.Users.AnyAsync(u => u.Email == email))
            return Conflict("An account with that email already exists.");

        if (!TryParseSelfSignupRole(dto.Role ?? nameof(UserRole.Teacher), out var role))
            return BadRequest("Role must be Teacher or Student.");

        // An account is a User (identity) + the profile matching its role. A
        // student registering here is the Method B path — they still need teacher
        // approval (via a class code) before joining any class.
        Teacher? teacher = null;
        Student? student = null;
        User user;
        if (role == UserRole.Teacher)
        {
            teacher = new Teacher
            {
                FirstName = dto.FirstName.Trim(),
                LastName = dto.LastName.Trim(),
            };
            user = new User { Email = email, Role = UserRole.Teacher, Teacher = teacher };
        }
        else
        {
            student = new Student
            {
                FirstName = dto.FirstName.Trim(),
                LastName = dto.LastName.Trim(),
                RegistrationType = StudentRegistrationType.SelfRegistered,
            };
            user = new User { Email = email, Role = UserRole.Student, Student = student };
        }
        user.PasswordHash = _hasher.HashPassword(user, dto.Password);

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return Ok(await IssueAsync(user, teacher, student));
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

    // ── Method A: Access Card passwordless login (ages 8-10) ────────────────

    /// Logs a young student in by their typed access code — no email/password.
    /// Rate-limited (the code is short and therefore guessable in bulk).
    [EnableRateLimiting("auth")]
    [HttpPost("access-code")]
    public async Task<ActionResult<AuthResponseDto>> AccessCode(AccessCodeLoginDto dto)
    {
        var code = dto.Code.Trim().ToUpperInvariant();
        var user = await _db.Users
            .Include(u => u.Student)
            .FirstOrDefaultAsync(u => u.AccessCode == code);
        if (user is null || user.Student is null)
            return Unauthorized("That access code is not valid.");

        return Ok(await IssueAsync(user, null, user.Student));
    }

    /// Logs a young student in by scanning their access-card QR. The QR encodes a
    /// long secret; we match on its hash (never stored in plaintext).
    [EnableRateLimiting("auth")]
    [HttpPost("access-qr")]
    public async Task<ActionResult<AuthResponseDto>> AccessQr(AccessQrLoginDto dto)
    {
        var hash = TokenService.HashToken(dto.Token.Trim());
        var user = await _db.Users
            .Include(u => u.Student)
            .FirstOrDefaultAsync(u => u.AccessQrTokenHash == hash);
        if (user is null || user.Student is null)
            return Unauthorized("That access card is not valid.");

        return Ok(await IssueAsync(user, null, user.Student));
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

        return await SocialSignInAsync(SocialProvider.Google, identity, dto.Role);
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

        return await SocialSignInAsync(SocialProvider.Apple, identity, dto.Role);
    }

    // Admin console sign-in via the server secret only (Admin:AccessSecret). No
    // email/password: verify the secret, find-or-create the single admin User,
    // and issue an Admin JWT — the same token shape the dashboard already uses.
    [EnableRateLimiting("auth")]
    [HttpPost("admin")]
    public async Task<ActionResult<AuthResponseDto>> Admin(AdminLoginDto dto)
    {
        if (string.IsNullOrWhiteSpace(_admin.AccessSecret))
            return Unauthorized("Admin login is not configured.");

        // Constant-time compare so a wrong secret can't be timed byte-by-byte.
        var provided = System.Text.Encoding.UTF8.GetBytes(dto.Secret);
        var expected = System.Text.Encoding.UTF8.GetBytes(_admin.AccessSecret);
        if (!CryptographicOperations.FixedTimeEquals(provided, expected))
            return Unauthorized("Invalid admin secret.");

        var email = (_admin.Email ?? "admin@teachertracker.local").Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user is null)
        {
            user = new User { Email = email, Role = UserRole.Admin };
            _db.Users.Add(user);
            await _db.SaveChangesAsync();
        }
        else if (user.Role != UserRole.Admin)
        {
            return Unauthorized("The configured admin email is already a non-admin account.");
        }

        return Ok(await IssueAsync(user, null, null));
    }

    private enum SocialProvider { Google, Apple }

    // Shared social sign-in: match the account by provider subject, else link by
    // verified email, else create a new account in the requested role (Teacher or
    // Student, never Admin). Issues our own token pair, so everything downstream
    // is identical to password login.
    private async Task<ActionResult<AuthResponseDto>> SocialSignInAsync(
        SocialProvider provider, SocialIdentity identity, string? requestedRole)
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

        // The role is chosen at signup; without a valid one, ask the client to
        // prompt for it (it re-sends the same token with the choice).
        if (!TryParseSelfSignupRole(requestedRole, out var role))
            return UnprocessableEntity(new { code = "role_required" });

        var firstName = identity.FirstName?.Trim() ?? string.Empty;
        var lastName = identity.LastName?.Trim() ?? string.Empty;

        // A pure-social account has no password until it sets one via
        // forgot/reset-password.
        User newUser;
        Teacher? teacher = null;
        Student? student = null;
        if (role == UserRole.Teacher)
        {
            teacher = new Teacher { FirstName = firstName, LastName = lastName };
            newUser = new User { Email = email, Role = UserRole.Teacher, Teacher = teacher };
        }
        else
        {
            // Self-registered student: belongs to no teacher (TeacherId null).
            student = new Student { FirstName = firstName, LastName = lastName };
            newUser = new User { Email = email, Role = UserRole.Student, Student = student };
        }
        LinkSubject(newUser, provider, identity.Subject);

        _db.Users.Add(newUser);
        await _db.SaveChangesAsync();

        return Ok(await IssueAsync(newUser, teacher, student));
    }

    private static void LinkSubject(User user, SocialProvider provider, string subject)
    {
        if (provider == SocialProvider.Google) user.GoogleSubject = subject;
        else user.AppleSubject = subject;
    }

    // A self-signup role must be Teacher or Student — never Admin (admin access is
    // secret-only, see the /admin endpoint).
    private static bool TryParseSelfSignupRole(string? requested, out UserRole role)
    {
        role = default;
        if (!Enum.TryParse(requested, ignoreCase: true, out UserRole parsed))
            return false;
        if (parsed != UserRole.Teacher && parsed != UserRole.Student)
            return false;
        role = parsed;
        return true;
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
        if (user is not null && user.Email is not null)
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

        // Demographic fields: only overwrite when the client sends a value, so a
        // partial profile edit never clears data the teacher set earlier. Blank
        // strings are normalized to null (treated as "not provided").
        if (dto.City is not null)
            teacher.City = Blank(dto.City);
        if (dto.District is not null)
            teacher.District = Blank(dto.District);
        if (dto.SchoolType is not null)
            teacher.SchoolType = dto.SchoolType;
        if (dto.EducationLevel is not null)
            teacher.EducationLevel = dto.EducationLevel;

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

    // Trim to null: an empty/whitespace demographic value means "not provided".
    private static string? Blank(string s) =>
        string.IsNullOrWhiteSpace(s) ? null : s.Trim();

    private static TeacherDto ToDto(Teacher t) =>
        new(t.Id, t.UserId, t.FirstName, t.LastName, t.User?.Email ?? string.Empty,
            t.AvatarFileObjectId, t.CoverFileObjectId,
            t.City, t.District, t.SchoolType, t.EducationLevel);

    private static TeacherDto ToDto(Teacher t, User u) =>
        new(t.Id, u.Id, t.FirstName, t.LastName, u.Email ?? string.Empty,
            t.AvatarFileObjectId, t.CoverFileObjectId,
            t.City, t.District, t.SchoolType, t.EducationLevel);

    private static StudentProfileDto ToProfileDto(Student s) =>
        new(s.Id, s.FirstName, s.LastName, s.StudentNumber);
}
