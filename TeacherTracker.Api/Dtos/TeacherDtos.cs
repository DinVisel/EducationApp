namespace TeacherTracker.Api.Dtos;

public record TeacherDto(
    int Id,
    string FirstName,
    string LastName,
    string Email,
    int? AvatarFileId = null,
    int? CoverFileId = null);
