using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// Covers self-service password change and the first-login (MustChangePassword)
/// gate for teacher-provisioned student accounts.
public class ChangePasswordTests
{
    private static HttpRequestMessage Req(HttpMethod method, string url, string token, object? body = null)
    {
        var req = new HttpRequestMessage(method, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null) req.Content = JsonContent.Create(body);
        return req;
    }

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
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("token").GetString()!;
    }

    /// Creates a student under the teacher and provisions a login; returns the
    /// student's login email + password.
    private static async Task<(string email, string password)> ProvisionStudentAsync(
        HttpClient c, string teacherToken)
    {
        var create = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", teacherToken,
            new { firstName = "Ada", lastName = "Lovelace", studentNumber = "S1" }));
        create.EnsureSuccessStatusCode();
        var studentId = (await create.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();

        const string email = "ada@students.local";
        const string password = "initpass1";
        var account = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/students/{studentId}/account",
            teacherToken, new { email, password }));
        account.EnsureSuccessStatusCode();
        return (email, password);
    }

    [Fact]
    public async Task Provisioned_Student_Login_Requires_Password_Change()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (email, password) = await ProvisionStudentAsync(c, teacher);

        var login = await c.PostAsJsonAsync("/api/v1/auth/login", new { email, password });
        login.EnsureSuccessStatusCode();
        var json = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Student", json.GetProperty("role").GetString());
        Assert.True(json.GetProperty("mustChangePassword").GetBoolean());
    }

    [Fact]
    public async Task Self_Registered_Teacher_Does_Not_Need_Password_Change()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "t@t.com");

        var login = await c.PostAsJsonAsync("/api/v1/auth/login",
            new { email = "t@t.com", password = "pass1234" });
        login.EnsureSuccessStatusCode();
        var json = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(json.GetProperty("mustChangePassword").GetBoolean());
    }

    [Fact]
    public async Task ChangePassword_Clears_The_Gate_And_Swaps_The_Password()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (email, password) = await ProvisionStudentAsync(c, teacher);

        var login = await c.PostAsJsonAsync("/api/v1/auth/login", new { email, password });
        var studentToken = (await login.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("token").GetString()!;

        var change = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/auth/change-password",
            studentToken, new { currentPassword = password, newPassword = "chosen99" }));
        change.EnsureSuccessStatusCode();
        // Returns a fresh token pair with the gate cleared so the session survives.
        var changeJson = await change.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(string.IsNullOrEmpty(changeJson.GetProperty("token").GetString()));
        Assert.False(changeJson.GetProperty("mustChangePassword").GetBoolean());

        // Old password rejected, new one works, and the gate is cleared.
        var oldLogin = await c.PostAsJsonAsync("/api/v1/auth/login", new { email, password });
        Assert.Equal(HttpStatusCode.Unauthorized, oldLogin.StatusCode);

        var newLogin = await c.PostAsJsonAsync("/api/v1/auth/login",
            new { email, password = "chosen99" });
        newLogin.EnsureSuccessStatusCode();
        var newJson = await newLogin.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(newJson.GetProperty("mustChangePassword").GetBoolean());
    }

    [Fact]
    public async Task ChangePassword_Rejects_A_Wrong_Current_Password()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (email, password) = await ProvisionStudentAsync(c, teacher);

        var login = await c.PostAsJsonAsync("/api/v1/auth/login", new { email, password });
        var studentToken = (await login.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("token").GetString()!;

        var change = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/auth/change-password",
            studentToken, new { currentPassword = "wrongpass", newPassword = "chosen99" }));
        Assert.Equal(HttpStatusCode.BadRequest, change.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_Requires_Authentication()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var change = await c.PostAsJsonAsync("/api/v1/auth/change-password",
            new { currentPassword = "x", newPassword = "chosen99" });
        Assert.Equal(HttpStatusCode.Unauthorized, change.StatusCode);
    }
}
