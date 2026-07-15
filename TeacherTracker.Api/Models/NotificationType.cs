namespace TeacherTracker.Api.Models;

/// What a <see cref="Notification"/> is about. Stored as text (see AppDbContext).
public enum NotificationType
{
    PostLiked,
    PostCommented,
    AssignmentAssigned,
    QuizAssigned,
}
