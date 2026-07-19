using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

public record RegisterDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [Required, EmailAddress, MaxLength(256)] string Email,
    [Required, MinLength(6), MaxLength(100)] string Password);

public record LoginDto(
    [Required, EmailAddress] string Email,
    [Required] string Password);

public record ForgotPasswordDto(
    [Required, EmailAddress, MaxLength(256)] string Email);

public record ResetPasswordDto(
    [Required] string Token,
    [Required, MinLength(6), MaxLength(100)] string NewPassword);

public record UpdateProfileDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [Required, EmailAddress, MaxLength(256)] string Email,
    // When provided, set the profile picture / cover to this owned file. Null
    // leaves the current image unchanged.
    int? AvatarFileId = null,
    int? CoverFileId = null);

public record ChangePasswordDto(
    [Required] string CurrentPassword,
    [Required, MinLength(6), MaxLength(100)] string NewPassword);

public record RefreshRequestDto(
    [Required] string RefreshToken);

public record LogoutRequestDto(
    [Required] string RefreshToken);

/// Returned by register/login/refresh: the short-lived access token (+ its
/// expiry), the rotating refresh token, the account role, the matching profile
/// (teacher or student, depending on the role), and whether the account must
/// change its password before continuing (first-login gate).
public record AuthResponseDto(
    string Token,
    string RefreshToken,
    DateTime AccessTokenExpiresAtUtc,
    string Role,
    TeacherDto? Teacher,
    StudentProfileDto? Student = null,
    bool MustChangePassword = false);

/// The current identity without a token — used to restore a session at startup
/// regardless of role. `MustChangePassword` gates first-login on the client.
public record SessionDto(
    string Role,
    TeacherDto? Teacher,
    StudentProfileDto? Student,
    bool MustChangePassword = false);
