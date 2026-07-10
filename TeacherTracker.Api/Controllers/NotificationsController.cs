using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;

namespace TeacherTracker.Api.Controllers;

/// The signed-in user's in-app notifications (any role). Everything is scoped to
/// the account id in the token; notifications are created inline by the actions
/// that trigger them (post likes/comments, new assignments).
[ApiController]
[Authorize]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _db;

    public NotificationsController(AppDbContext db)
    {
        _db = db;
    }

    private int UserId => User.GetUserId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<NotificationDto>>> GetAll()
    {
        var notifications = await _db.Notifications
            .AsNoTracking()
            .Where(n => n.RecipientUserId == UserId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new NotificationDto(
                n.Id, n.Type, n.Text, n.PostId, n.CreatedAt, n.ReadAt != null))
            .ToListAsync();

        return Ok(notifications);
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult<UnreadCountDto>> UnreadCount()
    {
        var count = await _db.Notifications
            .CountAsync(n => n.RecipientUserId == UserId && n.ReadAt == null);
        return Ok(new UnreadCountDto(count));
    }

    [HttpPost("{id:int}/read")]
    public async Task<IActionResult> MarkRead(int id)
    {
        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.RecipientUserId == UserId);
        if (notification is null)
            return NotFound();

        if (notification.ReadAt is null)
        {
            notification.ReadAt = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }

        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllRead()
    {
        await _db.Notifications
            .Where(n => n.RecipientUserId == UserId && n.ReadAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.ReadAt, DateTime.UtcNow));

        return NoContent();
    }
}
