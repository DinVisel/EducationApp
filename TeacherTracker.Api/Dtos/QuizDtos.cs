using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

// --- Teacher authoring (create) ---

/// One answer option when a teacher authors a question.
public record CreateQuizChoiceDto(
    [Required, MaxLength(500)] string Text,
    bool IsCorrect);

/// One question when a teacher authors a quiz; needs at least two choices and at
/// least one marked correct (validated in the controller).
public record CreateQuizQuestionDto(
    [Required, MaxLength(1000)] string Text,
    [MinLength(2)] IReadOnlyList<CreateQuizChoiceDto> Choices);

/// Payload to publish a quiz to a class.
public record CreateQuizDto(
    [Required, MaxLength(200)] string Title,
    [MaxLength(2000)] string? Description,
    QuizCategory Category,
    [MaxLength(200)] string? BookReference,
    [MinLength(1)] IReadOnlyList<CreateQuizQuestionDto> Questions);

// --- Teacher list/read ---

/// Summary of a quiz published to a class, with fan-out progress and the average
/// score across submitted attempts (0..100).
public record QuizDto(
    int Id,
    string Title,
    string? Description,
    QuizCategory Category,
    string? BookReference,
    DateTime CreatedAt,
    int ClassroomId,
    int QuestionCount,
    int AssignedCount,
    int SubmittedCount,
    double? AverageScorePct);

// --- Teacher analytics ---

/// One student's result on a quiz.
public record QuizStudentResultDto(
    int StudentId,
    string StudentName,
    bool IsSubmitted,
    int Score,
    int TotalQuestions,
    DateTime? SubmittedAt);

/// How a single choice fared across all submitted attempts.
public record QuizChoiceStatDto(
    int ChoiceId,
    string Text,
    bool IsCorrect,
    int ChosenCount);

/// Per-question analytics: how many submitted attempts got it right, plus the
/// distribution of chosen answers.
public record QuizQuestionStatDto(
    int QuestionId,
    string Text,
    double CorrectRatePct,
    IReadOnlyList<QuizChoiceStatDto> Choices);

/// Full analytics dashboard payload for one quiz.
public record QuizAnalyticsDto(
    int QuizId,
    string Title,
    int QuestionCount,
    int AssignedCount,
    int SubmittedCount,
    double? AverageScorePct,
    IReadOnlyList<QuizStudentResultDto> Results,
    IReadOnlyList<QuizQuestionStatDto> Questions);

// --- Student solving ---

/// A quiz in the student's list (their attempt), with class context and status.
public record StudentQuizSummaryDto(
    int AttemptId,
    int QuizId,
    string Title,
    QuizCategory Category,
    string? BookReference,
    string ClassName,
    int QuestionCount,
    bool IsSubmitted,
    int Score,
    int TotalQuestions);

/// A choice as shown to a student. `IsCorrect` is included so the gamified client
/// can give immediate per-card feedback; the server re-grades on submit, so a
/// tampered score can't be trusted.
public record StudentQuizChoiceDto(
    int Id,
    string Text,
    bool IsCorrect);

/// A question as shown to a student, with its choices.
public record StudentQuizQuestionDto(
    int QuestionId,
    string Text,
    IReadOnlyList<StudentQuizChoiceDto> Choices);

/// The full quiz a student solves — questions and choices for one attempt.
public record StudentQuizDetailDto(
    int AttemptId,
    int QuizId,
    string Title,
    string? Description,
    QuizCategory Category,
    string? BookReference,
    string ClassName,
    bool IsSubmitted,
    int Score,
    int TotalQuestions,
    IReadOnlyList<StudentQuizQuestionDto> Questions);

/// One answer in a submission.
public record SubmitQuizAnswerDto(
    int QuestionId,
    int ChoiceId);

/// A student's full submission for an attempt.
public record SubmitQuizDto(
    [MinLength(1)] IReadOnlyList<SubmitQuizAnswerDto> Answers);

/// The graded result returned right after submitting.
public record QuizResultDto(
    int Score,
    int TotalQuestions);
