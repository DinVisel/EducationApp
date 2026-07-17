using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// Admin-only moderation and account tooling. Admins review reports filed against
/// the social hub and either dismiss them or remove the offending content, and
/// can list all accounts.
[ApiController]
[ApiVersion("1.0")]
[Authorize(Roles = nameof(UserRole.Admin))]
[Route("api/v{version:apiVersion}/admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _db;

    public AdminController(AppDbContext db)
    {
        _db = db;
    }

    private int UserId => User.GetUserId();

    [HttpGet("reports")]
    public async Task<ActionResult<IEnumerable<ReportDto>>> GetReports(
        [FromQuery] bool resolved = false)
    {
        var reports = await _db.Reports
            .AsNoTracking()
            .Where(r => resolved ? r.ResolvedAt != null : r.ResolvedAt == null)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new ReportDto(
                r.Id,
                r.Reason,
                r.CreatedAt,
                r.Reporter!.Email,
                r.PostId != null ? "Post" : "Comment",
                r.PostId ?? r.PostCommentId,
                r.PostId != null
                    ? (r.Post != null ? r.Post.Text : null)
                    : (r.PostComment != null ? r.PostComment.Text : null),
                r.PostId != null
                    ? (r.Post != null
                        ? r.Post.Author!.Teacher!.FirstName + " " + r.Post.Author.Teacher.LastName
                        : null)
                    : (r.PostComment != null
                        ? r.PostComment.Author!.Teacher!.FirstName + " " + r.PostComment.Author.Teacher.LastName
                        : null),
                r.ResolvedAt != null,
                r.Resolution))
            .ToListAsync();

        return Ok(reports);
    }

    [HttpPost("reports/{id:int}/dismiss")]
    public async Task<IActionResult> Dismiss(int id)
    {
        var report = await _db.Reports.FirstOrDefaultAsync(r => r.Id == id);
        if (report is null)
            return NotFound();

        Resolve(report, ReportResolution.Dismissed);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// Removes the reported content (post or comment) and resolves the report.
    [HttpPost("reports/{id:int}/remove")]
    public async Task<IActionResult> RemoveContent(int id)
    {
        var report = await _db.Reports.FirstOrDefaultAsync(r => r.Id == id);
        if (report is null)
            return NotFound();

        if (report.PostId is int postId)
        {
            var post = await _db.Posts.FirstOrDefaultAsync(p => p.Id == postId);
            if (post is not null)
            {
                post.IsDeleted = true;
                post.DeletedAt = DateTime.UtcNow;
            }
        }
        else if (report.PostCommentId is int commentId)
        {
            var comment = await _db.PostComments.FirstOrDefaultAsync(c => c.Id == commentId);
            if (comment is not null) _db.PostComments.Remove(comment);
        }

        Resolve(report, ReportResolution.ContentRemoved);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<AdminUserDto>>> GetUsers()
    {
        var users = await _db.Users
            .AsNoTracking()
            .OrderBy(u => u.Id)
            .Select(u => new AdminUserDto(
                u.Id,
                u.Email,
                u.Role,
                u.Teacher != null
                    ? u.Teacher.FirstName + " " + u.Teacher.LastName
                    : (u.Student != null
                        ? u.Student.FirstName + " " + u.Student.LastName
                        : null),
                u.CreatedAt))
            .ToListAsync();

        return Ok(users);
    }

    private void Resolve(Report report, ReportResolution resolution)
    {
        report.Resolution = resolution;
        report.ResolvedAt = DateTime.UtcNow;
        report.ResolvedByUserId = UserId;
    }
}
