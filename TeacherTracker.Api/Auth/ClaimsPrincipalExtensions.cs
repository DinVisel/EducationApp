using System.Security.Claims;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Auth;

public static class ClaimsPrincipalExtensions
{
    /// The authenticated account's id, taken from the JWT subject claim.
    public static int GetUserId(this ClaimsPrincipal user)
    {
        // ASP.NET maps "sub" to NameIdentifier by default.
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? user.FindFirstValue("sub");
        if (value is null || !int.TryParse(value, out var id))
            throw new InvalidOperationException("Token is missing a valid user id.");
        return id;
    }

    /// The authenticated user's display name (from the `name` claim), used for
    /// notification text. Falls back to "Someone" when absent.
    public static string GetName(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue("name");
        return string.IsNullOrWhiteSpace(value) ? "Someone" : value;
    }

    /// The authenticated user's role.
    public static UserRole GetRole(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue("role") ?? user.FindFirstValue(ClaimTypes.Role);
        if (value is null || !Enum.TryParse<UserRole>(value, out var role))
            throw new InvalidOperationException("Token is missing a valid role.");
        return role;
    }

    /// The authenticated teacher profile's id. Only present when the account is a
    /// teacher; teacher-scoped controllers rely on this claim.
    public static int GetTeacherId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue("teacherId");
        if (value is null || !int.TryParse(value, out var id))
            throw new InvalidOperationException("Token is missing a valid teacher id.");
        return id;
    }

    /// The authenticated student profile's id. Only present when the account is a
    /// student; student-scoped endpoints rely on this claim.
    public static int GetStudentId(this ClaimsPrincipal user)
    {
        var value = user.FindFirstValue("studentId");
        if (value is null || !int.TryParse(value, out var id))
            throw new InvalidOperationException("Token is missing a valid student id.");
        return id;
    }
}
