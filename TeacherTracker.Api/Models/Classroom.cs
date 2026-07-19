namespace TeacherTracker.Api.Models;

/// A class/section owned by a teacher. Students join via <see cref="Enrollment"/>;
/// teachers assign work to a whole classroom at once (later phase).
public class Classroom
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    // Global, human-shareable join code (e.g. "MAT101") for Method B onboarding:
    // an older student types it in the app to request to join (see
    // ClassJoinRequest). Generated on create; unique (see AppDbContext).
    public string ClassCode { get; set; } = string.Empty;

    public int TeacherId { get; set; }
    public Teacher? Teacher { get; set; }

    public List<Enrollment> Enrollments { get; set; } = new();
}
