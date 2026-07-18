namespace TeacherTracker.Api.Models;

/// A student's attendance state for a given class day. Stored as text (see
/// AppDbContext).
public enum AttendanceStatus
{
    Present,
    Absent,
    Late,
    Excused,
}
