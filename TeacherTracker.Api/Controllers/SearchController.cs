using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// Global discovery search: finds teachers (by name) and materials — quizzes and
/// documents shared to the feed — with Subject / Grade / Material-Type filters.
/// Uses PostgreSQL full-text search (generated tsvector + GIN) in production and
/// a translatable LIKE fallback on the SQLite test provider.
[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/v{version:apiVersion}/search")]
public class SearchController : ControllerBase
{
    private readonly AppDbContext _db;

    public SearchController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<SearchResultsDto>> Search(
        [FromQuery] string? q,
        [FromQuery] string type = "all",
        [FromQuery] PostSubject? subject = null,
        [FromQuery] GradeLevel? grade = null,
        [FromQuery] int limit = 30)
    {
        var take = Math.Clamp(limit, 1, 50);
        var term = q?.Trim();
        var hasTerm = !string.IsNullOrWhiteSpace(term);
        var pg = _db.Database.IsNpgsql();

        var wantTeachers = type is "all" or "teachers";
        var wantQuizzes = type is "all" or "quizzes";
        var wantDocuments = type is "all" or "documents";

        // --- Teachers (matched by name; a term is required) ---
        var teachers = new List<TeacherResultDto>();
        if (wantTeachers && hasTerm)
        {
            var tq = _db.Teachers.AsNoTracking();
            tq = pg
                ? tq.Where(t => t.SearchVector.Matches(EF.Functions.PlainToTsQuery("english", term!)))
                : tq.Where(t => (t.FirstName + " " + t.LastName).ToLower().Contains(term!.ToLower()));

            teachers = await tq
                .OrderBy(t => t.FirstName).ThenBy(t => t.LastName)
                .Take(take)
                .Select(t => new TeacherResultDto(
                    t.UserId,
                    t.FirstName + " " + t.LastName,
                    t.AvatarFileObjectId))
                .ToListAsync();
        }

        var materials = new List<MaterialResultDto>();

        // --- Quiz materials (posts that share a quiz) ---
        if (wantQuizzes)
        {
            var query = _db.Posts.AsNoTracking().Where(p => p.SharedQuizId != null);
            if (subject != null) query = query.Where(p => p.Subject == subject);
            if (grade != null) query = query.Where(p => p.GradeLevel == grade);
            if (hasTerm)
                query = pg
                    ? query.Where(p => p.SharedQuiz!.SearchVector.Matches(
                        EF.Functions.PlainToTsQuery("english", term!)))
                    : query.Where(p => p.SharedQuiz!.Title.ToLower().Contains(term!.ToLower()));

            materials.AddRange(await query
                .OrderByDescending(p => p.Id)
                .Take(take)
                .Select(p => new MaterialResultDto(
                    "Quiz",
                    p.Id,
                    p.SharedQuiz!.Title,
                    p.Subject,
                    p.GradeLevel,
                    p.Author!.Teacher!.FirstName + " " + p.Author.Teacher.LastName,
                    p.SharedQuizId,
                    null))
                .ToListAsync());
        }

        // --- Document materials (document/PDF attachments on feed posts) ---
        if (wantDocuments)
        {
            // Document-ish MIME types (PDFs, Office/OpenDocument, plain text);
            // images and video are excluded. Inlined so EF translates it to SQL.
            var query = _db.PostAttachments.AsNoTracking()
                .Where(a =>
                    a.FileObject!.ContentType == "application/pdf"
                    || a.FileObject.ContentType == "text/plain"
                    || a.FileObject.ContentType.Contains("word")
                    || a.FileObject.ContentType.Contains("officedocument")
                    || a.FileObject.ContentType.Contains("presentation")
                    || a.FileObject.ContentType.Contains("spreadsheet")
                    || a.FileObject.ContentType.Contains("opendocument"));
            if (subject != null) query = query.Where(a => a.Post!.Subject == subject);
            if (grade != null) query = query.Where(a => a.Post!.GradeLevel == grade);
            if (hasTerm)
                query = pg
                    ? query.Where(a => a.FileObject!.SearchVector.Matches(
                        EF.Functions.PlainToTsQuery("english", term!)))
                    : query.Where(a => a.FileObject!.FileName.ToLower().Contains(term!.ToLower()));

            materials.AddRange(await query
                .OrderByDescending(a => a.Id)
                .Take(take)
                .Select(a => new MaterialResultDto(
                    "Document",
                    a.PostId,
                    a.FileObject!.FileName,
                    a.Post!.Subject,
                    a.Post.GradeLevel,
                    a.Post.Author!.Teacher!.FirstName + " " + a.Post.Author.Teacher.LastName,
                    null,
                    a.FileObjectId))
                .ToListAsync());
        }

        return Ok(new SearchResultsDto(teachers, materials));
    }
}
