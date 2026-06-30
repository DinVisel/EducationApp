using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

public record TeacherDto(
    int Id,
    string FirstName,
    string LastName,
    string Email);

public record CreateTeacherDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [Required, EmailAddress, MaxLength(256)] string Email);

public record UpdateTeacherDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [Required, EmailAddress, MaxLength(256)] string Email);
