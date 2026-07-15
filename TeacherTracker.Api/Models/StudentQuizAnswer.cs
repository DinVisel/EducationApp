namespace TeacherTracker.Api.Models;

/// A student's chosen answer for one question of a <see cref="StudentQuizAttempt"/>.
/// Persisted at submit time so teachers can review individual answers and
/// per-question analytics. <see cref="IsCorrect"/> is a snapshot graded on the
/// server against the choice's correctness at submission.
public class StudentQuizAnswer
{
    public int Id { get; set; }

    public int AttemptId { get; set; }
    public StudentQuizAttempt? Attempt { get; set; }

    public int QuestionId { get; set; }
    public int ChosenChoiceId { get; set; }

    public bool IsCorrect { get; set; }
}
