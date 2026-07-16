namespace TeacherTracker.Api.Models;

/// The school grade a shared material (post) targets, for search/discovery
/// filtering. Stored as text (see AppDbContext), like <see cref="PostSubject"/>.
public enum GradeLevel
{
    Kindergarten,
    Grade1,
    Grade2,
    Grade3,
    Grade4,
    Grade5,
    Grade6,
    Grade7,
    Grade8,
    Grade9,
    Grade10,
    Grade11,
    Grade12,
}
