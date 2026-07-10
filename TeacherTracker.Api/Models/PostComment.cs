namespace TeacherTracker.Api.Models;

/// A teacher's comment on a <see cref="Post"/> in the social hub.
public class PostComment
{
    public int Id { get; set; }

    public int PostId { get; set; }
    public Post? Post { get; set; }

    // The account (a teacher) that wrote the comment.
    public int AuthorUserId { get; set; }
    public User? Author { get; set; }

    public string Text { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
