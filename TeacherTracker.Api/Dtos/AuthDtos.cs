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

public record UpdateProfileDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [Required, EmailAddress, MaxLength(256)] string Email);

/// Returned by register/login: the signed token, the account role, and the
/// teacher profile (present when the account is a teacher).
public record AuthResponseDto(string Token, string Role, TeacherDto? Teacher);
