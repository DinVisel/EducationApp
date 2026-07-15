namespace TeacherTracker.Api.Models;

/// One question in a <see cref="Quiz"/>, with its multiple-choice options.
public class QuizQuestion
{
    public int Id { get; set; }

    public int QuizId { get; set; }
    public Quiz? Quiz { get; set; }

    public string Text { get; set; } = string.Empty;

    // Presentation order within the quiz.
    public int Order { get; set; }

    public List<QuizChoice> Choices { get; set; } = new();
}
