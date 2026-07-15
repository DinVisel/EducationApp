namespace TeacherTracker.Api.Models;

/// What a <see cref="Quiz"/> is about. Stored as text (see AppDbContext). A
/// BookExam pairs with the free-text <see cref="Quiz.BookReference"/>; Practice
/// and General are general-purpose homework-style quizzes.
public enum QuizCategory
{
    BookExam,
    Practice,
    General
}
