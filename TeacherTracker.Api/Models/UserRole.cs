namespace TeacherTracker.Api.Models;

/// The kind of account. Drives what a signed-in user can do; carried in the JWT.
public enum UserRole
{
    Teacher,
    Student,
    Admin,
}
