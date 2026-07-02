using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

public record StudentDto(
    int Id,
    string FirstName,
    string LastName,
    string StudentNumber,
    int TeacherId);

public record CreateStudentDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [MaxLength(50)] string StudentNumber);

public record UpdateStudentDto(
    [Required, MaxLength(100)] string FirstName,
    [Required, MaxLength(100)] string LastName,
    [MaxLength(50)] string StudentNumber);
