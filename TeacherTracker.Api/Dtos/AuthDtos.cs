using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

public record RegisterDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [Required, EmailAddress, MaxLength(256)] string Email,
    [Required, MinLength(6), MaxLength(100)] string Password,
    // "Teacher" (default) or "Student". A Student self-registers for the Method B
    // class-code flow; never "Admin" (admin sign-in is secret-only).
    string? Role = null);

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
    int? CoverFileId = null,
    // Demographic profile fields for growth analytics. Null leaves the current
    // value unchanged (so a partial edit doesn't wipe previously-set fields).
    [MaxLength(100)] string? City = null,
    [MaxLength(100)] string? District = null,
    SchoolType? SchoolType = null,
    EducationLevel? EducationLevel = null);

public record ChangePasswordDto(
    [Required] string CurrentPassword,
    [Required, MinLength(6), MaxLength(100)] string NewPassword);

public record RefreshRequestDto(
    [Required] string RefreshToken);

/// Sent to the social sign-in endpoints (/auth/google, /auth/apple): the
/// provider ID token to verify. [Nonce] (when the client used one) is checked
/// against the token's `nonce` claim. Apple only returns the user's name on the
/// first authorization, so the client forwards it here for account creation.
public record SocialLoginDto(
    [Required] string IdToken,
    string? Nonce = null,
    string? FirstName = null,
    string? LastName = null,
    // Chosen role for a NEW account: "Teacher" or "Student" (never "Admin").
    // Ignored for an existing account (its role is kept). When a new account
    // has no valid role, the endpoint replies 422 { code: "role_required" } so
    // the client can prompt for it.
    string? Role = null);

/// Admin console sign-in: a single server secret (Admin:AccessSecret). No email
/// or password — the backend verifies the secret and issues an Admin JWT.
public record AdminLoginDto(
    [Required] string Secret);

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
