using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using TeacherTracker.Api.Auth;

namespace TeacherTracker.Api.Hubs;

/// Real-time channel for in-app notifications. Each connection joins a group
/// keyed by the account id, so the server can push a lightweight "notification"
/// signal to exactly the recipients of a new notification. The client reacts by
/// re-fetching from the REST notifications API (this hub carries no payload), so
/// the socket stays a thin change-signal and polling remains a safe fallback.
[Authorize]
public class NotificationsHub : Hub
{
    /// The SignalR group a given account listens on.
    public static string GroupFor(int userId) => $"user-{userId}";

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User!.GetUserId();
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupFor(userId));
        await base.OnConnectedAsync();
    }
}
