namespace TeacherTracker.Api.Models;

/// A teacher's profile. Authentication (email/password) lives on the linked
/// <see cref="User"/>; this holds the teacher-specific fields.
public class Teacher
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;

    // The account this profile belongs to (1:1).
    public int UserId { get; set; }
    public User? User { get; set; }

    public List<Student> Students { get; set; } = new();
}
