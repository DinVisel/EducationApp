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

    // SHA-256 hex hash of an active password-reset token; null when none is
    // pending. Never store the raw token (mirrors why passwords are hashed).
    public string? PasswordResetTokenHash { get; set; }
    public DateTime? PasswordResetTokenExpiresAtUtc { get; set; }

    // Soft delete: rows are never physically removed, just hidden from normal
    // queries (see AppDbContext's global query filter) so audit history and
    // FK-referencing child rows survive.
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }

    // Audit trail: auto-populated by AuditInterceptor on save.
    public int? CreatedBy { get; set; }
    public DateTime? ModifiedAt { get; set; }
    public int? ModifiedBy { get; set; }

    // Linked profiles (at most one is set, matching Role).
    public Teacher? Teacher { get; set; }
    public Student? Student { get; set; }
}
