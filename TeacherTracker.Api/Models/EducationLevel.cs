namespace TeacherTracker.Api.Models;

/// The education level(s) a teacher teaches at. Collected during onboarding for
/// growth analytics. Stored as text (see AppDbContext).
public enum EducationLevel
{
    /// Primary school only (İlkokul).
    PrimarySchool,

    /// Middle school only (Ortaokul).
    MiddleSchool,

    /// Both primary and middle school.
    Both,
}
