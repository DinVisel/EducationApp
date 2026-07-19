namespace TeacherTracker.Api.Models;

public class Student
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string StudentNumber { get; set; } = string.Empty;

    // Detailed profile (all optional).
    public DateOnly? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? GuardianName { get; set; }
    public string? GuardianPhone { get; set; }
    public string? Notes { get; set; }

    // The teacher who provisioned this student. Null for a self-registered
    // student (social signup as Student) — they belong to no teacher until one
    // adds them.
    public int? TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    // Optional login account for the student (populated in the student module,
    // Phase 4). Null means the student is a passive record with no login.
    public int? UserId { get; set; }
    public User? User { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Soft delete: rows are never physically removed, just hidden from normal
    // queries (see AppDbContext's global query filter) so audit history and
    // FK-referencing child rows (notes, homework, books) survive.
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }

    // Audit trail: auto-populated by AuditInterceptor on save.
    public int? CreatedBy { get; set; }
    public DateTime? ModifiedAt { get; set; }
    public int? ModifiedBy { get; set; }

    public List<TrackingNote> TrackingNotes { get; set; } = new();
    public List<Homework> Homeworks { get; set; } = new();
    public List<Book> Books { get; set; } = new();
}
