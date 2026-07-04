namespace TeacherTracker.Api.Models;

/// Links an <see cref="Assignment"/> to a stored <see cref="FileObject"/> (in R2).
/// Attachments are shared by the whole class rather than duplicated per student.
public class AssignmentAttachment
{
    public int Id { get; set; }

    public int AssignmentId { get; set; }
    public Assignment? Assignment { get; set; }

    public int FileObjectId { get; set; }
    public FileObject? FileObject { get; set; }
}
