namespace TeacherTracker.Api.Models;

/// What a <see cref="Notification"/> is about. Stored as text (see AppDbContext).
public enum NotificationType
{
    PostLiked,
    PostCommented,
    AssignmentAssigned,
    QuizAssigned,
    QuizCloned,
    PostRated,

    // Method B onboarding (class-code Waiting Lobby).
    ClassJoinRequested, // → teacher: a student wants to join their class
    ClassJoinApproved,  // → student: the teacher accepted
    ClassJoinRejected,  // → student: the teacher declined
}
