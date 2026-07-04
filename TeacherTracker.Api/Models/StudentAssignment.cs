namespace TeacherTracker.Api.Models;

/// One enrolled student's copy of an <see cref="Assignment"/>, created by the
/// fan-out when a teacher publishes to a class. Tracks that student's progress;
/// the student module (Phase 4) reads and updates these.
public class StudentAssignment
{
    public int Id { get; set; }

    public int AssignmentId { get; set; }
    public Assignment? Assignment { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }

    public bool IsDone { get; set; }
    public DateTime? CompletedAt { get; set; }
}
