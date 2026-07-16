using NpgsqlTypes;

namespace TeacherTracker.Api.Models;

/// A multiple-choice quiz a teacher publishes to a whole <see cref="Classroom"/>.
/// Publishing fans out a <see cref="StudentQuizAttempt"/> to every enrolled
/// student. A quiz can be a book reading exam (with a free-text
/// <see cref="BookReference"/>) or general practice/homework — see
/// <see cref="QuizCategory"/>.
public class Quiz
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }

    public QuizCategory Category { get; set; } = QuizCategory.General;

    // Free-text book title/reference for a BookExam (Books are per-student logs,
    // so this is a label rather than a foreign key).
    public string? BookReference { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // The class this quiz targets.
    public int ClassroomId { get; set; }
    public Classroom? Classroom { get; set; }

    // The teacher who published it (owns the quiz for access checks).
    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    public List<QuizQuestion> Questions { get; set; } = new();
    public List<StudentQuizAttempt> Attempts { get; set; } = new();

    // Postgres full-text search vector generated from Title + Description (see
    // AppDbContext). Mapped only on Npgsql; unmapped (never set) on other providers.
    public NpgsqlTsVector SearchVector { get; set; } = null!;
}
