namespace TeacherTracker.Api.Models;

/// The "Waiting Lobby" for Method B onboarding. When a self-registered student
/// submits a class's global <see cref="Classroom.ClassCode"/>, a Pending request
/// is created here — deliberately *not* an <see cref="Enrollment"/>, so the
/// student gets no access (roster reads, assignment fan-out, quizzes) until a
/// teacher approves. Approval creates the Enrollment; the request row survives as
/// an audit trail either way.
public class ClassJoinRequest
{
    public int Id { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }

    public int ClassroomId { get; set; }
    public Classroom? Classroom { get; set; }

    public ClassJoinRequestStatus Status { get; set; } = ClassJoinRequestStatus.Pending;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Set when a teacher approves/rejects.
    public DateTime? DecidedAt { get; set; }
    public int? DecidedByTeacherId { get; set; }
}
