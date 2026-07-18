using System.Linq.Expressions;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;
using TeacherTracker.Api.Notifications;

namespace TeacherTracker.Api.Controllers;

/// Multiple-choice quizzes a teacher publishes to a class. Creating one fans out
/// a per-student <see cref="StudentQuizAttempt"/> to every currently enrolled
/// student. Scoped to the authenticated teacher's classes.
[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/classrooms/{classroomId:int}/quizzes")]
public class QuizzesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly INotificationPublisher _publisher;

    public QuizzesController(AppDbContext db, INotificationPublisher publisher)
    {
        _db = db;
        _publisher = publisher;
    }

    private int TeacherId => User.GetTeacherId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<QuizDto>>> GetAll(int classroomId)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var quizzes = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.ClassroomId == classroomId)
            .OrderByDescending(q => q.CreatedAt)
            .Select(Projection)
            .ToListAsync();

        return Ok(quizzes);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<QuizDto>> GetById(int classroomId, int id)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var quiz = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.Id == id && q.ClassroomId == classroomId)
            .Select(Projection)
            .FirstOrDefaultAsync();

        return quiz is null ? NotFound() : Ok(quiz);
    }

    [HttpPost]
    public async Task<ActionResult<QuizDto>> Create(int classroomId, CreateQuizDto dto)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        // Validate the authored questions: each needs >= 2 choices and at least
        // one correct answer.
        if (dto.Questions.Count == 0)
            return BadRequest("A quiz needs at least one question.");
        foreach (var q in dto.Questions)
        {
            if (q.Choices.Count < 2)
                return BadRequest("Each question needs at least two choices.");
            if (!q.Choices.Any(c => c.IsCorrect))
                return BadRequest("Each question needs at least one correct choice.");
        }

        // Fan-out targets: every student currently enrolled in the class.
        var enrolledStudentIds = await _db.Enrollments
            .Where(e => e.ClassroomId == classroomId)
            .Select(e => e.StudentId)
            .ToListAsync();

        var title = dto.Title.Trim();
        var quiz = new Quiz
        {
            Title = title,
            Description = dto.Description,
            Category = dto.Category,
            BookReference = string.IsNullOrWhiteSpace(dto.BookReference)
                ? null
                : dto.BookReference.Trim(),
            ClassroomId = classroomId,
            TeacherId = TeacherId,
            CreatedAt = DateTime.UtcNow,
            Questions = dto.Questions
                .Select((q, qi) => new QuizQuestion
                {
                    Text = q.Text.Trim(),
                    Order = qi,
                    Choices = q.Choices
                        .Select((c, ci) => new QuizChoice
                        {
                            Text = c.Text.Trim(),
                            IsCorrect = c.IsCorrect,
                            Order = ci,
                        })
                        .ToList(),
                })
                .ToList(),
            Attempts = enrolledStudentIds
                .Select(sid => new StudentQuizAttempt
                {
                    StudentId = sid,
                    TotalQuestions = dto.Questions.Count,
                })
                .ToList(),
        };

        _db.Quizzes.Add(quiz);

        // Notify every enrolled student who has a login account.
        var recipientUserIds = await _db.Students
            .Where(s => enrolledStudentIds.Contains(s.Id) && s.UserId != null)
            .Select(s => s.UserId!.Value)
            .ToListAsync();
        foreach (var userId in recipientUserIds)
            _db.Notifications.Add(new Notification
            {
                RecipientUserId = userId,
                Type = NotificationType.QuizAssigned,
                Text = $"New quiz: {title}",
            });

        await _db.SaveChangesAsync();
        await _publisher.NotifyAsync(recipientUserIds);

        var created = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.Id == quiz.Id)
            .Select(Projection)
            .FirstAsync();

        return CreatedAtAction(nameof(GetById),
            new { classroomId, id = quiz.Id }, created);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int classroomId, int id)
    {
        var quiz = await _db.Quizzes
            .FirstOrDefaultAsync(q =>
                q.Id == id && q.ClassroomId == classroomId && q.TeacherId == TeacherId);
        if (quiz is null)
            return NotFound();

        _db.Quizzes.Remove(quiz);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// Analytics dashboard: participation, average score, per-student results, and
    /// per-question correct-rate / answer distribution.
    [HttpGet("{id:int}/analytics")]
    public async Task<ActionResult<QuizAnalyticsDto>> Analytics(int classroomId, int id)
    {
        if (!await OwnsClassroomAsync(classroomId))
            return NotFound();

        var quiz = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.Id == id && q.ClassroomId == classroomId)
            .Select(q => new
            {
                q.Id,
                q.Title,
                Questions = q.Questions
                    .OrderBy(qq => qq.Order)
                    .Select(qq => new
                    {
                        qq.Id,
                        qq.Text,
                        Choices = qq.Choices
                            .OrderBy(c => c.Order)
                            .Select(c => new { c.Id, c.Text, c.IsCorrect })
                            .ToList(),
                    })
                    .ToList(),
                Attempts = q.Attempts
                    .Select(a => new
                    {
                        a.StudentId,
                        StudentName = a.Student!.FirstName + " " + a.Student.LastName,
                        a.IsSubmitted,
                        a.Score,
                        a.TotalQuestions,
                        a.SubmittedAt,
                        Answers = a.Answers.Select(an => new
                        {
                            an.QuestionId,
                            an.ChosenChoiceId,
                            an.IsCorrect,
                        }).ToList(),
                    })
                    .ToList(),
            })
            .FirstOrDefaultAsync();

        if (quiz is null)
            return NotFound();

        var submitted = quiz.Attempts.Where(a => a.IsSubmitted).ToList();
        double? averagePct = submitted.Count == 0
            ? null
            : submitted.Average(a =>
                a.TotalQuestions == 0 ? 0 : 100.0 * a.Score / a.TotalQuestions);

        // Per-question stats aggregated in memory over the loaded submitted
        // answers (avoids a GroupBy that Npgsql may not translate cleanly).
        var submittedAnswers = submitted.SelectMany(a => a.Answers).ToList();
        var questionStats = quiz.Questions.Select(qq =>
        {
            var answersForQ = submittedAnswers.Where(an => an.QuestionId == qq.Id).ToList();
            var correctRate = answersForQ.Count == 0
                ? 0.0
                : 100.0 * answersForQ.Count(an => an.IsCorrect) / answersForQ.Count;
            var choiceStats = qq.Choices.Select(c => new QuizChoiceStatDto(
                c.Id,
                c.Text,
                c.IsCorrect,
                answersForQ.Count(an => an.ChosenChoiceId == c.Id))).ToList();
            return new QuizQuestionStatDto(qq.Id, qq.Text, correctRate, choiceStats);
        }).ToList();

        var results = quiz.Attempts
            .OrderByDescending(a => a.IsSubmitted)
            .ThenByDescending(a => a.Score)
            .Select(a => new QuizStudentResultDto(
                a.StudentId,
                a.StudentName,
                a.IsSubmitted,
                a.Score,
                a.TotalQuestions,
                a.SubmittedAt))
            .ToList();

        return Ok(new QuizAnalyticsDto(
            quiz.Id,
            quiz.Title,
            quiz.Questions.Count,
            quiz.Attempts.Count,
            submitted.Count,
            averagePct,
            results,
            questionStats));
    }

    private Task<bool> OwnsClassroomAsync(int classroomId) =>
        _db.Classrooms.AnyAsync(c => c.Id == classroomId && c.TeacherId == TeacherId);

    // Reused across queries; kept as an Expression so EF translates the fan-out
    // counts and average to SQL.
    private static readonly Expression<Func<Quiz, QuizDto>> Projection = q =>
        new QuizDto(
            q.Id,
            q.Title,
            q.Description,
            q.Category,
            q.BookReference,
            q.CreatedAt,
            q.ClassroomId,
            q.Questions.Count,
            q.Attempts.Count,
            q.Attempts.Count(a => a.IsSubmitted),
            q.Attempts.Where(a => a.IsSubmitted && a.TotalQuestions > 0)
                .Average(a => (double?)(100.0 * a.Score / a.TotalQuestions)));
}
