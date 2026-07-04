namespace TeacherTracker.Api.Models;

/// Work a teacher publishes to a whole <see cref="Classroom"/>. Publishing
/// fans out a <see cref="StudentAssignment"/> to every enrolled student and may
/// carry downloadable <see cref="AssignmentAttachment"/>s (R2 files).
public class Assignment
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateOnly? DueDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // The class this work targets.
    public int ClassroomId { get; set; }
    public Classroom? Classroom { get; set; }

    // The teacher who published it (owns the assignment for access checks).
    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    public List<AssignmentAttachment> Attachments { get; set; } = new();
    public List<StudentAssignment> StudentAssignments { get; set; } = new();
}
