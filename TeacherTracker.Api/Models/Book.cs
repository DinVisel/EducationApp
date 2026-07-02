namespace TeacherTracker.Api.Models;

/// Status of a book in a student's reading log.
public enum BookStatus
{
    Reading,
    Completed
}

public class Book
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Author { get; set; }
    public BookStatus Status { get; set; } = BookStatus.Reading;
    public int? Rating { get; set; } // 1..5, optional
    public DateTime CreatedAt { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }
}
