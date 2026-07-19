using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

public record StudentDto(
    int Id,
    string FirstName,
    string LastName,
    string StudentNumber,
    DateOnly? DateOfBirth,
    string? Gender,
    string? GuardianName,
    string? GuardianPhone,
    string? Notes,
    int? TeacherId);

public record CreateStudentDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [MaxLength(50)] string StudentNumber,
    DateOnly? DateOfBirth,
    [MaxLength(20)] string? Gender,
    [MaxLength(150)] string? GuardianName,
    [MaxLength(30)] string? GuardianPhone,
    [MaxLength(2000)] string? Notes);

public record UpdateStudentDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [MaxLength(50)] string StudentNumber,
    DateOnly? DateOfBirth,
    [MaxLength(20)] string? Gender,
    [MaxLength(150)] string? GuardianName,
    [MaxLength(30)] string? GuardianPhone,
    [MaxLength(2000)] string? Notes);
