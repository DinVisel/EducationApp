namespace TeacherTracker.Api.Models;

/// One answer option for a <see cref="QuizQuestion"/>. Exactly one (or more)
/// choice is flagged <see cref="IsCorrect"/>; the flag is sent to the student
/// client for immediate feedback and used server-side to grade a submission.
public class QuizChoice
{
    public int Id { get; set; }

    public int QuestionId { get; set; }
    public QuizQuestion? Question { get; set; }

    public string Text { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }

    // Presentation order within the question.
    public int Order { get; set; }
}
