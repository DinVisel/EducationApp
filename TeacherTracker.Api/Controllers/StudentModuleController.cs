using System.Linq.Expressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// The student-facing module: a signed-in student sees their own profile, the
/// classes they're enrolled in, and the assignments fanned out to them, and can
/// mark work done. Everything is scoped to the student id carried in the token.
[ApiController]
[Authorize(Roles = nameof(UserRole.Student))]
[Route("api/student")]
public class StudentModuleController : ControllerBase
{
    private readonly AppDbContext _db;

    public StudentModuleController(AppDbContext db)
    {
        _db = db;
    }

    private int StudentId => User.GetStudentId();

    [HttpGet("me")]
    public async Task<ActionResult<StudentProfileDto>> Me()
    {
        var me = await _db.Students
            .AsNoTracking()
            .Where(s => s.Id == StudentId)
            .Select(s => new StudentProfileDto(
                s.Id, s.FirstName, s.LastName, s.StudentNumber))
            .FirstOrDefaultAsync();

        return me is null ? NotFound() : Ok(me);
    }

    [HttpGet("classes")]
    public async Task<ActionResult<IEnumerable<StudentClassDto>>> Classes()
    {
        var classes = await _db.Enrollments
            .AsNoTracking()
            .Where(e => e.StudentId == StudentId)
            .Select(e => e.Classroom!)
            .OrderBy(c => c.Name)
            .Select(c => new StudentClassDto(
                c.Id,
                c.Name,
                c.Teacher!.FirstName + " " + c.Teacher.LastName))
            .ToListAsync();

        return Ok(classes);
    }

    [HttpGet("assignments")]
    public async Task<ActionResult<IEnumerable<StudentAssignmentDto>>> Assignments()
    {
        var assignments = await _db.StudentAssignments
            .AsNoTracking()
            .Where(sa => sa.StudentId == StudentId)
            .OrderBy(sa => sa.IsDone)
            .ThenBy(sa => sa.Assignment!.DueDate ?? DateOnly.MaxValue)
            .ThenByDescending(sa => sa.Assignment!.CreatedAt)
            .Select(Projection)
            .ToListAsync();

        return Ok(assignments);
    }

    [HttpPost("assignments/{id:int}/complete")]
    public Task<IActionResult> Complete(int id) => SetDone(id, true);

    [HttpPost("assignments/{id:int}/uncomplete")]
    public Task<IActionResult> Uncomplete(int id) => SetDone(id, false);

    // Toggles the student's own copy; `id` is the StudentAssignment id.
    private async Task<IActionResult> SetDone(int id, bool done)
    {
        var sa = await _db.StudentAssignments
            .FirstOrDefaultAsync(x => x.Id == id && x.StudentId == StudentId);
        if (sa is null)
            return NotFound();

        sa.IsDone = done;
        sa.CompletedAt = done ? DateTime.UtcNow : null;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // --- Quizzes ---

    [HttpGet("quizzes")]
    public async Task<ActionResult<IEnumerable<StudentQuizSummaryDto>>> Quizzes()
    {
        var quizzes = await _db.StudentQuizAttempts
            .AsNoTracking()
            .Where(a => a.StudentId == StudentId)
            .OrderBy(a => a.IsSubmitted)
            .ThenByDescending(a => a.Quiz!.CreatedAt)
            .Select(a => new StudentQuizSummaryDto(
                a.Id,
                a.QuizId,
                a.Quiz!.Title,
                a.Quiz.Category,
                a.Quiz.BookReference,
                a.Quiz.Classroom!.Name,
                a.Quiz.Questions.Count,
                a.IsSubmitted,
                a.Score,
                a.TotalQuestions))
            .ToListAsync();

        return Ok(quizzes);
    }

    [HttpGet("quizzes/{attemptId:int}")]
    public async Task<ActionResult<StudentQuizDetailDto>> Quiz(int attemptId)
    {
        var quiz = await _db.StudentQuizAttempts
            .AsNoTracking()
            .Where(a => a.Id == attemptId && a.StudentId == StudentId)
            .Select(a => new StudentQuizDetailDto(
                a.Id,
                a.QuizId,
                a.Quiz!.Title,
                a.Quiz.Description,
                a.Quiz.Category,
                a.Quiz.BookReference,
                a.Quiz.Classroom!.Name,
                a.IsSubmitted,
                a.Score,
                a.TotalQuestions,
                a.Quiz.Questions
                    .OrderBy(q => q.Order)
                    .Select(q => new StudentQuizQuestionDto(
                        q.Id,
                        q.Text,
                        q.Choices
                            .OrderBy(c => c.Order)
                            .Select(c => new StudentQuizChoiceDto(c.Id, c.Text, c.IsCorrect))
                            .ToList()))
                    .ToList()))
            .FirstOrDefaultAsync();

        return quiz is null ? NotFound() : Ok(quiz);
    }

    [HttpPost("quizzes/{attemptId:int}/submit")]
    public async Task<ActionResult<QuizResultDto>> SubmitQuiz(int attemptId, SubmitQuizDto dto)
    {
        var attempt = await _db.StudentQuizAttempts
            .Include(a => a.Quiz!).ThenInclude(q => q.Questions).ThenInclude(q => q.Choices)
            .FirstOrDefaultAsync(a => a.Id == attemptId && a.StudentId == StudentId);
        if (attempt is null)
            return NotFound();
        if (attempt.IsSubmitted)
            return Conflict("This quiz has already been submitted.");

        var questions = attempt.Quiz!.Questions;

        // Grade authoritatively on the server: keep only one answer per question,
        // and only for choices that actually belong to that question.
        var chosenByQuestion = dto.Answers
            .GroupBy(x => x.QuestionId)
            .ToDictionary(g => g.Key, g => g.Last().ChoiceId);

        var score = 0;
        foreach (var question in questions)
        {
            if (!chosenByQuestion.TryGetValue(question.Id, out var chosenChoiceId))
                continue;
            var choice = question.Choices.FirstOrDefault(c => c.Id == chosenChoiceId);
            if (choice is null)
                continue; // choice from another question; ignore

            var isCorrect = choice.IsCorrect;
            if (isCorrect)
                score++;

            attempt.Answers.Add(new StudentQuizAnswer
            {
                QuestionId = question.Id,
                ChosenChoiceId = choice.Id,
                IsCorrect = isCorrect,
            });
        }

        attempt.IsSubmitted = true;
        attempt.Score = score;
        attempt.TotalQuestions = questions.Count;
        attempt.SubmittedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new QuizResultDto(score, questions.Count));
    }

    // Translatable projection: the student's copy joined to the class assignment,
    // its class name, and the teacher's attachments.
    private static readonly Expression<Func<StudentAssignment, StudentAssignmentDto>>
        Projection = sa => new StudentAssignmentDto(
            sa.Id,
            sa.AssignmentId,
            sa.Assignment!.Title,
            sa.Assignment.Description,
            sa.Assignment.DueDate,
            sa.Assignment.Classroom!.Name,
            sa.IsDone,
            sa.CompletedAt,
            sa.Assignment.Attachments
                .Select(at => new AssignmentAttachmentDto(
                    at.FileObject!.Id,
                    at.FileObject.FileName,
                    at.FileObject.ContentType,
                    at.FileObject.Size))
                .ToList());
}
