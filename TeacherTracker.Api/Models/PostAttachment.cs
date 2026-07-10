namespace TeacherTracker.Api.Models;

/// Links a <see cref="Post"/> to a stored <see cref="FileObject"/> (in R2).
/// Mirrors <see cref="AssignmentAttachment"/>: the link is shared by the feed,
/// and deleting it never removes the underlying file bytes.
public class PostAttachment
{
    public int Id { get; set; }

    public int PostId { get; set; }
    public Post? Post { get; set; }

    public int FileObjectId { get; set; }
    public FileObject? FileObject { get; set; }
}
