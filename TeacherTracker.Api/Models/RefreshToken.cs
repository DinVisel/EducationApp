namespace TeacherTracker.Api.Models;

/// A long-lived refresh token paired with a short-lived access JWT. Only the
/// SHA-256 hash of the raw token is stored (never the raw value, mirroring how
/// passwords and reset tokens are handled). Tokens rotate on every use: the old
/// row is revoked and linked to its replacement, so a stolen-and-reused token can
/// be detected.
public class RefreshToken
{
    public int Id { get; set; }

    // The account this token authenticates.
    public int UserId { get; set; }
    public User? User { get; set; }

    // SHA-256 hex hash of the raw token handed to the client.
    public string TokenHash { get; set; } = string.Empty;

    public DateTime ExpiresAtUtc { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Set when the token is rotated (on refresh) or explicitly revoked (on logout).
    public DateTime? RevokedAtUtc { get; set; }

    // The hash of the token that superseded this one (set on rotation), so a
    // reused revoked token can be traced to its chain.
    public string? ReplacedByTokenHash { get; set; }

    public bool IsActive => RevokedAtUtc is null && DateTime.UtcNow < ExpiresAtUtc;
}
