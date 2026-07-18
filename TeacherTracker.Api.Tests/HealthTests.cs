using System.Net;
using TeacherTracker.Api.Middleware;
using Xunit;

namespace TeacherTracker.Api.Tests;

public class HealthTests
{
    [Fact]
    public async Task Health_Returns_Ok()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var res = await c.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        var body = await res.Content.ReadAsStringAsync();
        Assert.Equal("Healthy", body);
    }

    [Fact]
    public async Task Supplied_RequestId_Is_Echoed_Back()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var req = new HttpRequestMessage(HttpMethod.Get, "/health");
        req.Headers.Add(RequestIdMiddleware.HeaderName, "test-correlation-123");
        var res = await c.SendAsync(req);

        Assert.True(res.Headers.TryGetValues(RequestIdMiddleware.HeaderName, out var values));
        Assert.Equal("test-correlation-123", values!.Single());
    }

    [Fact]
    public async Task RequestId_Is_Generated_When_Absent()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var res = await c.GetAsync("/health");

        Assert.True(res.Headers.TryGetValues(RequestIdMiddleware.HeaderName, out var values));
        Assert.False(string.IsNullOrWhiteSpace(values!.Single()));
    }
}
