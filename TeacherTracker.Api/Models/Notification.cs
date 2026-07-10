namespace TeacherTracker.Api.Models;

/// An in-app notification for one <see cref="User"/> (any role). Created inline
/// when something happens to them — their post is liked/commented, or work is
/// assigned to them. Polled by the client; marked read via the notifications API.
public class Notification
{
    public int Id { get; set; }

    // The account this notification is for.
    public int RecipientUserId { get; set; }
    public User? Recipient { get; set; }

    public NotificationType Type { get; set; }
    public string Text { get; set; } = string.Empty;

    // The post a like/comment notification points at (null for assignments).
    public int? PostId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Null until the recipient reads it.
    public DateTime? ReadAt { get; set; }
}
