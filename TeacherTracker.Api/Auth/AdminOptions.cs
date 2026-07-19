namespace TeacherTracker.Api.Auth;

/// Bound from the "Admin" configuration section. Admin access is secret-based:
/// present [AccessSecret] to /auth/admin to receive an Admin JWT. [Email] is the
/// identity the single admin account uses (find-or-created on first login).
/// Populate via env/user-secrets, never commit real values.
public class AdminOptions
{
    public const string SectionName = "Admin";

    public string? Email { get; set; }
    public string? AccessSecret { get; set; }
}
