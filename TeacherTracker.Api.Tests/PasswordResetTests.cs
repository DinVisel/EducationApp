using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Models;
using Xunit;

namespace TeacherTracker.Api.Tests;

public class PasswordResetTests
{
    private static async Task<string> RegisterTeacherAsync(HttpClient c, string email, string password = "pass1234")
    {
        var res = await c.PostAsJsonAsync("/api/v1/auth/register", new
        {
            firstName = "Test",
            lastName = "Teacher",
            email,
            password,
        });
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("token").GetString()!;
    }

    private static string ExtractToken(string body)
    {
        var match = Regex.Match(body, @"reset your password: (\S+)");
        Assert.True(match.Success, $"Could not find a token in: {body}");
        return match.Groups[1].Value;
    }

    [Fact]
    public async Task ForgotPassword_Then_ResetPassword_Changes_The_Password()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "a@t.com", "oldpass1");

        var forgot = await c.PostAsJsonAsync("/api/v1/auth/forgot-password", new { email = "a@t.com" });
        Assert.Equal(HttpStatusCode.OK, forgot.StatusCode);
        Assert.Single(factory.EmailService.Sent);
        var token = ExtractToken(factory.EmailService.Sent[0].Body);

        var reset = await c.PostAsJsonAsync("/api/v1/auth/reset-password",
            new { token, newPassword = "newpass1" });
        Assert.Equal(HttpStatusCode.OK, reset.StatusCode);

        var oldLogin = await c.PostAsJsonAsync("/api/v1/auth/login",
            new { email = "a@t.com", password = "oldpass1" });
        Assert.Equal(HttpStatusCode.Unauthorized, oldLogin.StatusCode);

        var newLogin = await c.PostAsJsonAsync("/api/v1/auth/login",
            new { email = "a@t.com", password = "newpass1" });
        Assert.Equal(HttpStatusCode.OK, newLogin.StatusCode);
    }

    [Fact]
    public async Task ForgotPassword_For_Unknown_Email_Still_Returns_200_And_Sends_Nothing()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var res = await c.PostAsJsonAsync("/api/v1/auth/forgot-password", new { email = "nobody@t.com" });
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
        Assert.Empty(factory.EmailService.Sent);
    }

    [Fact]
    public async Task ResetPassword_Rejects_An_Expired_Token()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "a@t.com");

        const string rawToken = "expired-token";
        await factory.WithDbAsync(async db =>
        {
            var user = await db.Users.FirstAsync(u => u.Email == "a@t.com");
            user.PasswordResetTokenHash = System.Convert.ToHexString(
                System.Security.Cryptography.SHA256.HashData(
                    System.Text.Encoding.UTF8.GetBytes(rawToken)));
            user.PasswordResetTokenExpiresAtUtc = System.DateTime.UtcNow.AddMinutes(-1);
            await db.SaveChangesAsync();
        });

        var reset = await c.PostAsJsonAsync("/api/v1/auth/reset-password",
            new { token = rawToken, newPassword = "newpass1" });
        Assert.Equal(HttpStatusCode.BadRequest, reset.StatusCode);
    }

    [Fact]
    public async Task ResetPassword_Rejects_An_Unknown_Token()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var reset = await c.PostAsJsonAsync("/api/v1/auth/reset-password",
            new { token = "garbage", newPassword = "newpass1" });
        Assert.Equal(HttpStatusCode.BadRequest, reset.StatusCode);
    }
}
