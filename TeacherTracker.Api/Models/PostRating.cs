namespace TeacherTracker.Api.Models;

/// A teacher's 1–5 star rating of a <see cref="Post"/> that shares a quiz. The
/// pair is unique (see AppDbContext) so a teacher rates a post at most once;
/// re-rating updates the existing row.
public class PostRating
{
    public int Id { get; set; }

    public int PostId { get; set; }
    public Post? Post { get; set; }

    // The account (a teacher) that rated the post.
    public int UserId { get; set; }
    public User? User { get; set; }

    // 1..5 stars.
    public int Value { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
