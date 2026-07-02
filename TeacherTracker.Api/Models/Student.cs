namespace TeacherTracker.Api.Models;

public class Student
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string StudentNumber { get; set; } = string.Empty;

    // Detailed profile (all optional).
    public DateOnly? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public string? GuardianName { get; set; }
    public string? GuardianPhone { get; set; }
    public string? Notes { get; set; }

    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    public List<TrackingNote> TrackingNotes { get; set; } = new();
    public List<Homework> Homeworks { get; set; } = new();
    public List<Book> Books { get; set; } = new();
}
