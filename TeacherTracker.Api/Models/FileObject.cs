using NpgsqlTypes;

namespace TeacherTracker.Api.Models;

/// Metadata for a file stored in R2. The bytes live in the bucket under
/// <see cref="Key"/>; this row tracks ownership and display info so the API can
/// broker downloads and enforce access.
public class FileObject
{
    public int Id { get; set; }

    // Object key within the R2 bucket (e.g. "uploads/{userId}/{guid}.pdf").
    public string Key { get; set; } = string.Empty;

    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long Size { get; set; }

    // The account that uploaded the file.
    public int OwnerUserId { get; set; }
    public User? Owner { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Postgres full-text search vector generated from FileName (see AppDbContext).
    // Mapped only on Npgsql; unmapped (never set) on other providers.
    public NpgsqlTsVector SearchVector { get; set; } = null!;
}
