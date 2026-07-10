namespace TeacherTracker.Api.Models;

/// The subject/tag a social-hub <see cref="Post"/> is filed under. A fixed set so
/// the feed can offer clean filtering. Stored as text (see AppDbContext).
public enum PostSubject
{
    General,
    Math,
    Reading,
    Science,
    SocialStudies,
    Art,
    Music,
    PhysicalEducation,
}
