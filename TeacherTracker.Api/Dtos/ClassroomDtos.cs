using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

/// A classroom in list form, with how many students are enrolled.
public record ClassroomDto(int Id, string Name, int StudentCount);

/// A classroom with its full roster.
public record ClassroomDetailDto(
    int Id,
    string Name,
    IReadOnlyList<StudentDto> Students);

public record CreateClassroomDto(
    [Required, MaxLength(100)] string Name);

public record UpdateClassroomDto(
    [Required, MaxLength(100)] string Name);
