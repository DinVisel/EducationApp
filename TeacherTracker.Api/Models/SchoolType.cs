namespace TeacherTracker.Api.Models;

/// The kind of school a teacher works at. Collected during onboarding so admins
/// can segment growth for targeted B2B sales. Stored as text (see AppDbContext).
public enum SchoolType
{
    /// A public/state-funded school.
    State,

    /// A private/independent school.
    Private,

    /// Anything that doesn't fit State or Private (e.g. tutoring centre).
    Other,
}
