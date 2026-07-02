namespace TeacherTracker.Api.Models;

public class Homework
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateOnly? DueDate { get; set; }
    public bool IsDone { get; set; }
    public DateTime CreatedAt { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }
}
