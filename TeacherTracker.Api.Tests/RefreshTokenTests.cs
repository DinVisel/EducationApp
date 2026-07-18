using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// Covers the access/refresh token lifecycle: login issues a refresh token,
/// refresh rotates it, reusing a rotated/revoked token is rejected, logout
/// revokes, and expired refresh tokens fail.
public class RefreshTokenTests
{
    private static async Task<(string access, string refresh)> RegisterAsync(HttpClient c, string email)
    {
        var res = await c.PostAsJsonAsync("/api/v1/auth/register", new
        {
            firstName = "Test",
            lastName = "Teacher",
            email,
            password = "pass1234",
        });
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return (json.GetProperty("token").GetString()!, json.GetProperty("refreshToken").GetString()!);
    }

    [Fact]
    public async Task Register_Returns_AccessAndRefresh_Tokens()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var (access, refresh) = await RegisterAsync(c, "a@t.com");

        Assert.False(string.IsNullOrWhiteSpace(access));
        Assert.False(string.IsNullOrWhiteSpace(refresh));
    }

    [Fact]
    public async Task Refresh_Rotates_And_Old_Token_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var (_, refresh) = await RegisterAsync(c, "a@t.com");

        var res = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        var newRefresh = json.GetProperty("refreshToken").GetString()!;
        Assert.NotEqual(refresh, newRefresh);
        Assert.False(string.IsNullOrWhiteSpace(json.GetProperty("token").GetString()));

        // The new token works (rotates again into a third token).
        var again = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = newRefresh });
        Assert.Equal(HttpStatusCode.OK, again.StatusCode);

        // The original, now-rotated token must be rejected. (Reuse detection also
        // revokes the chain — see Reusing_Revoked_Token_Revokes_The_Whole_Chain.)
        var reuse = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal(HttpStatusCode.Unauthorized, reuse.StatusCode);
    }

    [Fact]
    public async Task Reusing_Revoked_Token_Revokes_The_Whole_Chain()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var (_, refresh) = await RegisterAsync(c, "a@t.com");

        // Rotate once → `refresh` is now revoked, a new one is active.
        var res = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = refresh });
        var newRefresh = (await res.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("refreshToken").GetString()!;

        // Replaying the revoked token trips reuse detection...
        var reuse = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal(HttpStatusCode.Unauthorized, reuse.StatusCode);

        // ...which also invalidates the otherwise-active descendant.
        var descendant = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = newRefresh });
        Assert.Equal(HttpStatusCode.Unauthorized, descendant.StatusCode);
    }

    [Fact]
    public async Task Logout_Revokes_The_Refresh_Token()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var (access, refresh) = await RegisterAsync(c, "a@t.com");

        var req = new HttpRequestMessage(HttpMethod.Post, "/api/v1/auth/logout")
        {
            Content = JsonContent.Create(new { refreshToken = refresh }),
        };
        req.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", access);
        var logout = await c.SendAsync(req);
        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);

        var refreshRes = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal(HttpStatusCode.Unauthorized, refreshRes.StatusCode);
    }

    [Fact]
    public async Task Expired_Refresh_Token_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var (_, refresh) = await RegisterAsync(c, "a@t.com");

        await factory.WithDbAsync(async db =>
        {
            await db.RefreshTokens.ExecuteUpdateAsync(s =>
                s.SetProperty(t => t.ExpiresAtUtc, DateTime.UtcNow.AddDays(-1)));
        });

        var res = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Invalid_Refresh_Token_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterAsync(c, "a@t.com");

        var res = await c.PostAsJsonAsync("/api/v1/auth/refresh", new { refreshToken = "not-a-real-token" });
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }
}
