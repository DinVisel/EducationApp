namespace TeacherTracker.Api.Models;

/// Join between a <see cref="Student"/> and a <see cref="Classroom"/>. A student
/// may belong to many classrooms; the pair is unique (see AppDbContext).
public class Enrollment
{
    public int Id { get; set; }

    public int StudentId { get; set; }
    public Student? Student { get; set; }

    public int ClassroomId { get; set; }
    public Classroom? Classroom { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
