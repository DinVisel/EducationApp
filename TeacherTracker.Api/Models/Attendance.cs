namespace TeacherTracker.Api.Models;

/// One student's attendance record for a class on a specific day. A student has
/// at most one record per classroom per date (unique index in AppDbContext), so
/// marking is an upsert. Owned by the teacher who marked it.
public class Attendance
{
    public int Id { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }

    public int ClassroomId { get; set; }
    public Classroom? Classroom { get; set; }

    // The class day this record is for (date only, no time component).
    public DateOnly Date { get; set; }

    public AttendanceStatus Status { get; set; }

    // Optional free-text note (e.g. reason for an excused absence).
    public string? Note { get; set; }

    // The teacher who recorded/last updated it.
    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ModifiedAt { get; set; }
}
