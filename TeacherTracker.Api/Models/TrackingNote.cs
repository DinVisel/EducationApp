namespace TeacherTracker.Api.Models;

/// A timestamped observation about a student (behavior, progress, etc.).
public class TrackingNote
{
    public int Id { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }
}
