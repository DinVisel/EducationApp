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

/// Cross-class quiz endpoints for feed discovery: list the teacher's own quizzes
/// (to share), preview a shared quiz, and clone ("Assign to My Class") a shared
/// quiz into one of the caller's classrooms. Unlike <see cref="QuizzesController"/>
/// these are not nested under a classroom.
[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/quizzes")]
public class SharedQuizzesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly INotificationPublisher _publisher;

    public SharedQuizzesController(AppDbContext db, INotificationPublisher publisher)
    {
        _db = db;
        _publisher = publisher;
    }

    private int TeacherId => User.GetTeacherId();

    /// The caller's own quizzes across all their classes (for the share picker).
    [HttpGet("mine")]
    public async Task<ActionResult<IEnumerable<MyQuizDto>>> Mine()
    {
        var quizzes = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.TeacherId == TeacherId)
            .OrderByDescending(q => q.CreatedAt)
            .Select(q => new MyQuizDto(
                q.Id,
                q.Title,
                q.Category,
                q.Classroom!.Name,
                q.Questions.Count))
            .ToListAsync();

        return Ok(quizzes);
    }

    /// Full content of a shared (or own) quiz, for previewing before cloning.
    [HttpGet("{id:int}/preview")]
    public async Task<ActionResult<QuizPreviewDto>> Preview(int id)
    {
        var preview = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.Id == id && (q.TeacherId == TeacherId
                || _db.Posts.Any(p => p.SharedQuizId == q.Id)))
            .Select(q => new QuizPreviewDto(
                q.Id,
                q.Title,
                q.Description,
                q.Category,
                q.BookReference,
                q.Teacher!.FirstName + " " + q.Teacher.LastName,
                q.Questions
                    .OrderBy(qq => qq.Order)
                    .Select(qq => new QuizPreviewQuestionDto(
                        qq.Text,
                        qq.Choices
                            .OrderBy(c => c.Order)
                            .Select(c => new QuizPreviewChoiceDto(c.Text, c.IsCorrect))
                            .ToList()))
                    .ToList()))
            .FirstOrDefaultAsync();

        return preview is null ? NotFound() : Ok(preview);
    }

    /// Clone a shared quiz into one of the caller's classrooms, fanning out a
    /// fresh attempt to every enrolled student ("Assign to My Class").
    [HttpPost("{id:int}/clone")]
    public async Task<ActionResult<QuizDto>> Clone(int id, CloneQuizDto dto)
    {
        // Target classroom must belong to the caller.
        if (!await _db.Classrooms.AnyAsync(c => c.Id == dto.ClassroomId && c.TeacherId == TeacherId))
            return NotFound();

        // Source quiz must be shared to the feed (or the caller's own).
        var source = await _db.Quizzes
            .AsNoTracking()
            .Where(q => q.Id == id && (q.TeacherId == TeacherId
                || _db.Posts.Any(p => p.SharedQuizId == q.Id)))
            .Select(q => new
            {
                q.Title,
                q.Description,
                q.Category,
                q.BookReference,
                AuthorUserId = q.Teacher!.UserId,
                Questions = q.Questions
                    .OrderBy(qq => qq.Order)
                    .Select(qq => new
                    {
                        qq.Text,
                        qq.Order,
                        Choices = qq.Choices
                            .OrderBy(c => c.Order)
                            .Select(c => new { c.Text, c.IsCorrect, c.Order })
                            .ToList(),
                    })
                    .ToList(),
            })
            .FirstOrDefaultAsync();
        if (source is null)
            return NotFound();

        // Fan-out targets: every student currently enrolled in the target class.
        var enrolledStudentIds = await _db.Enrollments
            .Where(e => e.ClassroomId == dto.ClassroomId)
            .Select(e => e.StudentId)
            .ToListAsync();

        var quiz = new Quiz
        {
            Title = source.Title,
            Description = source.Description,
            Category = source.Category,
            BookReference = source.BookReference,
            ClassroomId = dto.ClassroomId,
            TeacherId = TeacherId,
            CreatedAt = DateTime.UtcNow,
            Questions = source.Questions
                .Select(q => new QuizQuestion
                {
                    Text = q.Text,
                    Order = q.Order,
                    Choices = q.Choices
                        .Select(c => new QuizChoice
                        {
                            Text = c.Text,
                            IsCorrect = c.IsCorrect,
                            Order = c.Order,
                        })
                        .ToList(),
                })
                .ToList(),
            Attempts = enrolledStudentIds
                .Select(sid => new StudentQuizAttempt
                {
                    StudentId = sid,
                    TotalQuestions = source.Questions.Count,
                })
                .ToList(),
        };

        _db.Quizzes.Add(quiz);

        // Notify each enrolled student who has a login account.
        var recipientUserIds = await _db.Students
            .Where(s => enrolledStudentIds.Contains(s.Id) && s.UserId != null)
            .Select(s => s.UserId!.Value)
            .ToListAsync();
        foreach (var userId in recipientUserIds)
            _db.Notifications.Add(new Notification
            {
                RecipientUserId = userId,
                Type = NotificationType.QuizAssigned,
                Text = $"New quiz: {source.Title}",
            });

        // Notify the original author that their quiz was cloned (not when cloning your own).
        var notifyAuthor = source.AuthorUserId != User.GetUserId();
        if (notifyAuthor)
            _db.Notifications.Add(new Notification
            {
                RecipientUserId = source.AuthorUserId,
                Type = NotificationType.QuizCloned,
                Text = $"{User.GetName()} assigned your quiz \"{source.Title}\" to their class",
            });

        await _db.SaveChangesAsync();

        var pushTargets = notifyAuthor
            ? recipientUserIds.Append(source.AuthorUserId)
            : recipientUserIds;
        await _publisher.NotifyAsync(pushTargets);

        return Ok(new QuizDto(
            quiz.Id,
            quiz.Title,
            quiz.Description,
            quiz.Category,
            quiz.BookReference,
            quiz.CreatedAt,
            quiz.ClassroomId,
            source.Questions.Count,
            enrolledStudentIds.Count,
            0,
            null));
    }
}
