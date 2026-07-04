namespace TeacherTracker.Api.Models;

/// The unified account/identity. Every person who can log in — teacher, student,
/// or admin — has exactly one <see cref="User"/>. Role-specific data lives in a
/// linked profile (e.g. <see cref="Teacher"/>, <see cref="Student"/>).
public class User
{
    public int Id { get; set; }

    // Login identifier; unique (see AppDbContext).
    public string Email { get; set; } = string.Empty;

    // Hashed with ASP.NET Core's PasswordHasher; never store or return plaintext.
    public string PasswordHash { get; set; } = string.Empty;

    public UserRole Role { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Linked profiles (at most one is set, matching Role).
    public Teacher? Teacher { get; set; }
    public Student? Student { get; set; }
}
