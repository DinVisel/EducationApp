using System.Net;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// The SignalR notifications hub must reject unauthenticated connections. Full
/// push E2E is out of scope for the integration suite (it needs a live socket +
/// two accounts); the change-signal behaviour is exercised indirectly by the
/// notification-creating endpoints in the other test classes.
public class NotificationsHubTests
{
    [Fact]
    public async Task Hub_Rejects_Unauthenticated_Negotiate()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        // The SignalR negotiate handshake is a POST to the hub path; without a
        // token the [Authorize] hub must return 401.
        var res = await c.PostAsync("/hubs/notifications/negotiate?negotiateVersion=1", null);

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }
}
