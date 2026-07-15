namespace TeacherTracker.Api.Models;

/// One enrolled student's copy of a <see cref="Quiz"/>, created by the fan-out
/// when a teacher publishes to a class. A single attempt is allowed: once
/// <see cref="IsSubmitted"/>, the score is locked. The student module reads and
/// submits these.
public class StudentQuizAttempt
{
    public int Id { get; set; }

    public int QuizId { get; set; }
    public Quiz? Quiz { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }

    public bool IsSubmitted { get; set; }

    // Number of questions answered correctly (authoritative, recomputed on the
    // server at submit time).
    public int Score { get; set; }

    // Snapshot of the quiz's question count when submitted, so scores stay
    // meaningful even if the quiz is later edited.
    public int TotalQuestions { get; set; }

    public DateTime? SubmittedAt { get; set; }

    public List<StudentQuizAnswer> Answers { get; set; } = new();
}
