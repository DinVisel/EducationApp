namespace TeacherTracker.Api.Models;

/// A class/section owned by a teacher. Students join via <see cref="Enrollment"/>;
/// teachers assign work to a whole classroom at once (later phase).
public class Classroom
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    public List<Enrollment> Enrollments { get; set; } = new();
}
