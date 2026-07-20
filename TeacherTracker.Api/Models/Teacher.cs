using NpgsqlTypes;

namespace TeacherTracker.Api.Models;

/// A teacher's profile. Authentication (email/password) lives on the linked
/// <see cref="User"/>; this holds the teacher-specific fields.
public class Teacher
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;

    // The account this profile belongs to (1:1).
    public int UserId { get; set; }
    public User? User { get; set; }

    // Demographic data collected during onboarding / profile setup, used by the
    // admin analytics dashboard to segment teacher growth. All nullable: rows that
    // predate this feature (and social/quick signups) haven't filled them in yet.
    public string? City { get; set; }
    public string? District { get; set; }
    public SchoolType? SchoolType { get; set; }
    public EducationLevel? EducationLevel { get; set; }

    // Optional profile picture and cover photo (uploaded files in R2).
    public int? AvatarFileObjectId { get; set; }
    public FileObject? AvatarFileObject { get; set; }
    public int? CoverFileObjectId { get; set; }
    public FileObject? CoverFileObject { get; set; }

    public List<Student> Students { get; set; } = new();

    // Postgres full-text search vector generated from FirstName + LastName (see
    // AppDbContext). Mapped only on Npgsql; unmapped (never set) on other providers.
    public NpgsqlTsVector SearchVector { get; set; } = null!;
}
