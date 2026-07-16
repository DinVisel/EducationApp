namespace TeacherTracker.Api.Models;

/// A message in the global teacher social hub. Any teacher can post text under a
/// <see cref="PostSubject"/> with downloadable <see cref="PostAttachment"/>s
/// (R2 files), and others can <see cref="PostLike"/> and <see cref="PostComment"/>.
/// Unlike assignments, the feed is global — not scoped to one teacher's students.
public class Post
{
    public int Id { get; set; }

    // The account (a teacher) that authored the post.
    public int AuthorUserId { get; set; }
    public User? Author { get; set; }

    public string Text { get; set; } = string.Empty;
    public PostSubject Subject { get; set; }

    // Optional grade the shared material targets (search/discovery filter).
    public GradeLevel? GradeLevel { get; set; }

    // When set, this post shares one of the author's quizzes to the feed, which
    // other teachers can rate and clone. SetNull on quiz delete keeps the post.
    public int? SharedQuizId { get; set; }
    public Quiz? SharedQuiz { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Instagram-style: the author can pin their own posts to the top of their
    // profile. Does not affect the global feed order.
    public bool IsPinned { get; set; }

    public List<PostAttachment> Attachments { get; set; } = new();
    public List<PostLike> Likes { get; set; } = new();
    public List<PostComment> Comments { get; set; } = new();
    public List<PostRating> Ratings { get; set; } = new();
}
