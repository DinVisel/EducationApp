namespace TeacherTracker.Api.Models;

public class Teacher
{
    public int Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;

    // Hashed with ASP.NET Core's PasswordHasher; never store or return plaintext.
    public string PasswordHash { get; set; } = string.Empty;

    public List<Student> Students { get; set; } = new();
}