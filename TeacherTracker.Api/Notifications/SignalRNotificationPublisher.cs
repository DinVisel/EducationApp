using Microsoft.AspNetCore.SignalR;
using TeacherTracker.Api.Hubs;

namespace TeacherTracker.Api.Notifications;

/// Broadcasts the change signal to each recipient's SignalR group. The event
/// name is "notification"; it carries no data — the client re-fetches unread
/// count / list from the REST API on receipt.
public class SignalRNotificationPublisher : INotificationPublisher
{
    private readonly IHubContext<NotificationsHub> _hub;

    public SignalRNotificationPublisher(IHubContext<NotificationsHub> hub)
    {
        _hub = hub;
    }

    public async Task NotifyAsync(IEnumerable<int> recipientUserIds)
    {
        foreach (var userId in recipientUserIds.Distinct())
            await _hub.Clients.Group(NotificationsHub.GroupFor(userId))
                .SendAsync("notification");
    }
}
