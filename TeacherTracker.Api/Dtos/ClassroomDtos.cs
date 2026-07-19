using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

/// A classroom in list form, with how many students are enrolled. ClassCode is
/// the global Method B join code the teacher shares with older students.
public record ClassroomDto(int Id, string Name, string ClassCode, int StudentCount);

/// A classroom with its full roster.
public record ClassroomDetailDto(
    int Id,
    string Name,
    string ClassCode,
    IReadOnlyList<StudentDto> Students);

public record CreateClassroomDto(
    [Required, MaxLength(100)] string Name);

public record UpdateClassroomDto(
    [Required, MaxLength(100)] string Name);
