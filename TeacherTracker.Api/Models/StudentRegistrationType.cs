namespace TeacherTracker.Api.Models;

/// How a <see cref="Student"/> record came into being. Drives which onboarding
/// pipeline provisioned them; stored as text (see AppDbContext).
public enum StudentRegistrationType
{
    /// Teacher created the profile directly (the original flow); no self-login
    /// unless a teacher later provisions credentials. The default for all rows
    /// that predate the hybrid-onboarding feature.
    TeacherManaged,

    /// Method A: teacher bulk-provisioned the student with a short Access Code /
    /// QR card. Logs in passwordlessly with the code (ages 8-10).
    AccessCard,

    /// Method B: the student registered themselves with email/password and joined
    /// a class via a Class Code + teacher approval (ages 11-16).
    SelfRegistered,
}
