using System.Security.Claims;

namespace TeacherTracker.Api.Auth;

public static class ClaimsPrincipalExtensions
{
    /// The authenticated teacher's id, taken from the JWT subject claim.
    public static int GetTeacherId(this ClaimsPrincipal user)
    {
        // ASP.NET maps "sub" to NameIdentifier by default.
        var value = user.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? user.FindFirstValue("sub");
        if (value is null || !int.TryParse(value, out var id))
            throw new InvalidOperationException("Token is missing a valid teacher id.");
        return id;
    }
}
