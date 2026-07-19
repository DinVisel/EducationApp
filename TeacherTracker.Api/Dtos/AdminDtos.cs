using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// A user account as an admin sees it. `Role` serializes as its enum name.
/// `IsBanned` reflects the soft-delete flag — banned users are hidden from the
/// rest of the app but still listed here so an admin can restore them.
public record AdminUserDto(
    int Id,
    string Email,
    UserRole Role,
    string? Name,
    DateTime CreatedAt,
    bool IsBanned);

/// Body for changing a user's role.
public record UpdateUserRoleDto(
    [Required] UserRole Role);
