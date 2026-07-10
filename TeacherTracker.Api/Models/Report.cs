namespace TeacherTracker.Api.Models;

/// A user's report of a <see cref="Post"/> or <see cref="PostComment"/> in the
/// social hub. Reviewed by an admin, who either dismisses it or removes the
/// offending content. Exactly one of <see cref="PostId"/>/<see cref="PostCommentId"/>
/// is set.
public class Report
{
    public int Id { get; set; }

    // Who filed the report.
    public int ReporterUserId { get; set; }
    public User? Reporter { get; set; }

    // The reported target (one is set).
    public int? PostId { get; set; }
    public Post? Post { get; set; }

    public int? PostCommentId { get; set; }
    public PostComment? PostComment { get; set; }

    public string Reason { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Resolution (null until an admin acts).
    public ReportResolution? Resolution { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public int? ResolvedByUserId { get; set; }
}
