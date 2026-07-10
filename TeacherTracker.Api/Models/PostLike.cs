namespace TeacherTracker.Api.Models;

/// A teacher's like on a <see cref="Post"/>. The pair is unique (see AppDbContext)
/// so a teacher likes a post at most once.
public class PostLike
{
    public int Id { get; set; }

    public int PostId { get; set; }
    public Post? Post { get; set; }

    // The account (a teacher) that liked the post.
    public int UserId { get; set; }
    public User? User { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
