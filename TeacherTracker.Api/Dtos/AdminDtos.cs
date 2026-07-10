using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// A user account as an admin sees it. `Role` serializes as its enum name.
public record AdminUserDto(
    int Id,
    string Email,
    UserRole Role,
    string? Name,
    DateTime CreatedAt);
