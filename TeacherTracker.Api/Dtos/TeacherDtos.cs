using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

public record TeacherDto(
    int Id,
    // The account (User) id — carried as a post's AuthorUserId, and used by the
    // client to tell its own profile from another teacher's.
    int UserId,
    string FirstName,
    string LastName,
    string Email,
    int? AvatarFileId = null,
    int? CoverFileId = null,
    // Demographic profile fields (null until the teacher fills them in).
    string? City = null,
    string? District = null,
    SchoolType? SchoolType = null,
    EducationLevel? EducationLevel = null);
