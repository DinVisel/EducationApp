using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

public record HomeworkDto(
    int Id,
    string Title,
    string? Description,
    DateOnly? DueDate,
    bool IsDone,
    DateTime CreatedAt,
    int StudentId);

public record CreateHomeworkDto(
    [Required, MaxLength(200)] string Title,
    [MaxLength(2000)] string? Description,
    DateOnly? DueDate,
    bool IsDone);

public record UpdateHomeworkDto(
    [Required, MaxLength(200)] string Title,
    [MaxLength(2000)] string? Description,
    DateOnly? DueDate,
    bool IsDone);
