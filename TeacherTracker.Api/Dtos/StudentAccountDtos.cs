using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

/// A teacher provisions a login for one of their students (credential flow —
/// no email infra yet, so the teacher sets the initial password and shares it).
public record CreateStudentAccountDto(
    [Required, EmailAddress, MaxLength(256)] string Email,
    [Required, MinLength(6), MaxLength(100)] string Password);

/// Whether a student currently has a login account, and under which email.
public record StudentAccountDto(bool HasAccount, string? Email);
