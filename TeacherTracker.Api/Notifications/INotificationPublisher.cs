namespace TeacherTracker.Api.Notifications;

/// Pushes a real-time "you have a new notification" signal to recipients over
/// SignalR. Abstracted so controllers depend on the intent, not the transport
/// (and so tests can substitute a no-op).
public interface INotificationPublisher
{
    /// Signals each recipient account (by user id) that their notifications
    /// changed. Callers invoke this *after* persisting the notification rows.
    Task NotifyAsync(IEnumerable<int> recipientUserIds);
}
