using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// An in-app notification for the signed-in user. `Type` serializes as its enum
/// name (JsonStringEnumConverter).
public record NotificationDto(
    int Id,
    NotificationType Type,
    string Text,
    int? PostId,
    DateTime CreatedAt,
    bool IsRead);

/// The signed-in user's unread notification count.
public record UnreadCountDto(int Count);
