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
/// the social hub and either dismiss them or remove the offending content, manage
/// accounts (list, ban/unban, change role), and read platform-wide analytics.
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

    /// Paginated, searchable roster of all accounts (including banned ones, so an
    /// admin can restore them). `search` matches email or profile name; `role`
    /// filters by account type. Offset paging with a total count for a page-number
    /// table. Banned = soft-deleted, so the query ignores the global filter.
    [HttpGet("users")]
    public async Task<ActionResult<PagedResult<AdminUserDto>>> GetUsers(
        [FromQuery] string? search = null,
        [FromQuery] UserRole? role = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25)
    {
        page = Math.Max(page, 1);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var query = _db.Users.AsNoTracking().IgnoreQueryFilters();

        if (role is not null)
            query = query.Where(u => u.Role == role);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                u.Email.ToLower().Contains(term)
                || (u.Teacher != null
                    && (u.Teacher.FirstName + " " + u.Teacher.LastName).ToLower().Contains(term))
                || (u.Student != null
                    && (u.Student.FirstName + " " + u.Student.LastName).ToLower().Contains(term)));
        }

        var total = await query.CountAsync();

        var users = await query
            .OrderBy(u => u.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new AdminUserDto(
                u.Id,
                u.Email,
                u.Role,
                u.Teacher != null
                    ? u.Teacher.FirstName + " " + u.Teacher.LastName
                    : (u.Student != null
                        ? u.Student.FirstName + " " + u.Student.LastName
                        : null),
                u.CreatedAt,
                u.IsDeleted))
            .ToListAsync();

        return Ok(new PagedResult<AdminUserDto>(users, total, page, pageSize));
    }

    /// Bans a user by soft-deleting the account: they can no longer sign in and are
    /// hidden from the rest of the app, but the row (and their content) survives.
    /// Admins can't ban themselves or other admins.
    [HttpPost("users/{id:int}/ban")]
    public async Task<IActionResult> BanUser(int id)
    {
        if (id == UserId)
            return BadRequest("You can't ban your own account.");

        var user = await _db.Users.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == id);
        if (user is null)
            return NotFound();
        if (user.Role == UserRole.Admin)
            return BadRequest("Admin accounts can't be banned.");
        if (user.IsDeleted)
            return NoContent();

        user.IsDeleted = true;
        user.DeletedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// Lifts a ban, restoring the account. No-op if the user isn't banned.
    [HttpPost("users/{id:int}/unban")]
    public async Task<IActionResult> UnbanUser(int id)
    {
        var user = await _db.Users.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == id);
        if (user is null)
            return NotFound();
        if (!user.IsDeleted)
            return NoContent();

        user.IsDeleted = false;
        user.DeletedAt = null;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    /// Changes a user's role. An admin can't strip their own admin role (so they
    /// don't lock themselves out).
    [HttpPost("users/{id:int}/role")]
    public async Task<ActionResult<AdminUserDto>> ChangeRole(int id, UpdateUserRoleDto dto)
    {
        if (id == UserId && dto.Role != UserRole.Admin)
            return BadRequest("You can't remove your own admin role.");

        var user = await _db.Users.IgnoreQueryFilters()
            .Include(u => u.Teacher)
            .Include(u => u.Student)
            .FirstOrDefaultAsync(u => u.Id == id);
        if (user is null)
            return NotFound();

        user.Role = dto.Role;
        await _db.SaveChangesAsync();

        var name = user.Teacher != null
            ? user.Teacher.FirstName + " " + user.Teacher.LastName
            : (user.Student != null
                ? user.Student.FirstName + " " + user.Student.LastName
                : null);

        return Ok(new AdminUserDto(
            user.Id, user.Email, user.Role, name, user.CreatedAt, user.IsDeleted));
    }

    /// Platform-wide analytics: headline KPIs plus 30-day daily time series for new
    /// signups and new posts. Soft-deleted users/posts are excluded (global filter);
    /// grouping is done provider-side then gap-filled in memory so it works on both
    /// Postgres and the SQLite test provider.
    [HttpGet("stats")]
    public async Task<ActionResult<AdminOverviewDto>> GetStats()
    {
        var now = DateTime.UtcNow;
        var since7 = now.AddDays(-7);
        var windowStart = now.Date.AddDays(-29); // 30 inclusive days

        var stats = new AdminStatsDto(
            TotalUsers: await _db.Users.CountAsync(),
            TotalTeachers: await _db.Users.CountAsync(u => u.Role == UserRole.Teacher),
            TotalStudents: await _db.Users.CountAsync(u => u.Role == UserRole.Student),
            TotalAdmins: await _db.Users.CountAsync(u => u.Role == UserRole.Admin),
            TotalClassrooms: await _db.Classrooms.CountAsync(),
            TotalPosts: await _db.Posts.CountAsync(),
            TotalQuizzes: await _db.Quizzes.CountAsync(),
            OpenReports: await _db.Reports.CountAsync(r => r.ResolvedAt == null),
            NewUsersLast7Days: await _db.Users.CountAsync(u => u.CreatedAt >= since7),
            PostsLast7Days: await _db.Posts.CountAsync(p => p.CreatedAt >= since7));

        var signupBuckets = await _db.Users
            .Where(u => u.CreatedAt >= windowStart)
            .GroupBy(u => u.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync();

        var postBuckets = await _db.Posts
            .Where(p => p.CreatedAt >= windowStart)
            .GroupBy(p => p.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync();

        return Ok(new AdminOverviewDto(
            stats,
            FillDailySeries(signupBuckets.ToDictionary(b => b.Date, b => b.Count), windowStart, now.Date),
            FillDailySeries(postBuckets.ToDictionary(b => b.Date, b => b.Count), windowStart, now.Date)));
    }

    /// Turns sparse per-day counts into a continuous daily series (zero-filled)
    /// from `start` through `end` inclusive.
    private static List<TimeSeriesPointDto> FillDailySeries(
        IReadOnlyDictionary<DateTime, int> counts, DateTime start, DateTime end)
    {
        var series = new List<TimeSeriesPointDto>();
        for (var day = start; day <= end; day = day.AddDays(1))
            series.Add(new TimeSeriesPointDto(
                DateOnly.FromDateTime(day),
                counts.TryGetValue(day, out var c) ? c : 0));
        return series;
    }

    private void Resolve(Report report, ReportResolution resolution)
    {
        report.Resolution = resolution;
        report.ResolvedAt = DateTime.UtcNow;
        report.ResolvedByUserId = UserId;
    }
}
