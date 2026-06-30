namespace TeacherTracker.Api.Models;

public class Student
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string StudentNumber { get; set; } = string.Empty;

    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }
}