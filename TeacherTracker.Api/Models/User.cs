namespace TeacherTracker.Api.Models;

/// The unified account/identity. Every person who can log in — teacher, student,
/// or admin — has exactly one <see cref="User"/>. Role-specific data lives in a
/// linked profile (e.g. <see cref="Teacher"/>, <see cref="Student"/>).
public class User
{
    public int Id { get; set; }

    // Login identifier for email/password and social accounts; unique (see
    // AppDbContext). Null for a Method A "access card" student — they log in with
    // an AccessCode/QR instead of an email, and the unique index treats NULLs as
    // distinct (same trick as GoogleSubject/AppleSubject) so many code-only
    // students don't collide.
    public string? Email { get; set; }

    // Hashed with ASP.NET Core's PasswordHasher; never store or return plaintext.
    // Empty for pure-social and access-card accounts (no password login).
    public string PasswordHash { get; set; } = string.Empty;

    public UserRole Role { get; set; }

    // Method A (Access Card) passwordless login for young students. The typed
    // AccessCode is short and human-friendly ("A3B7Q9"); the QR encodes a long
    // random secret whose SHA-256 we store (never the raw value, mirroring
    // password-reset tokens). Both are unique and null for every non-card account.
    public string? AccessCode { get; set; }
    public string? AccessQrTokenHash { get; set; }

    // Provider subject ids ("sub" claim) for social sign-in. Each is the stable,
    // per-app identifier the provider assigns to the user; null until the account
    // links that provider. Unique (see AppDbContext) so a subject maps to one
    // account. A pure-social account has an empty PasswordHash (no password login
    // until it sets one via forgot/reset-password).
    public string? GoogleSubject { get; set; }
    public string? AppleSubject { get; set; }

    // Forces a password change on next sign-in. Set when a teacher provisions a
    // student login (the teacher picked the initial password), cleared once the
    // student sets their own via /auth/change-password.
    public bool MustChangePassword { get; set; }

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
