using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Identity;
using TeacherTracker.Api.Models;
using Xunit;

namespace TeacherTracker.Api.Tests;

public class ApiTests
{
    // --- helpers ---------------------------------------------------------------

    private static async Task<string> RegisterTeacherAsync(HttpClient c, string email)
    {
        var res = await c.PostAsJsonAsync("/api/auth/register", new
        {
            firstName = "Test",
            lastName = "Teacher",
            email,
            password = "pass1234",
        });
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("token").GetString()!;
    }

    private static HttpRequestMessage Req(HttpMethod method, string url, string token, object? body = null)
    {
        var req = new HttpRequestMessage(method, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null) req.Content = JsonContent.Create(body);
        return req;
    }

    private static async Task<int> CreatePostAsync(HttpClient c, string token, string text, string subject = "Math")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", token,
            new { text, subject }));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("id").GetInt32();
    }

    // Seeds an admin directly, then logs in to get a token.
    private static async Task<string> CreateAdminAndLoginAsync(TestApiFactory factory, HttpClient c, string email)
    {
        await factory.WithDbAsync(async db =>
        {
            var admin = new User { Email = email, Role = UserRole.Admin };
            admin.PasswordHash = new PasswordHasher<User>().HashPassword(admin, "pass1234");
            db.Users.Add(admin);
            await db.SaveChangesAsync();
        });
        var res = await c.PostAsJsonAsync("/api/auth/login", new { email, password = "pass1234" });
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("token").GetString()!;
    }

    // --- tests -----------------------------------------------------------------

    [Fact]
    public async Task Register_Then_Login_Issues_Teacher_Token()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var token = await RegisterTeacherAsync(c, "a@t.com");
        Assert.False(string.IsNullOrWhiteSpace(token));

        var login = await c.PostAsJsonAsync("/api/auth/login",
            new { email = "a@t.com", password = "pass1234" });
        login.EnsureSuccessStatusCode();
        var json = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Teacher", json.GetProperty("role").GetString());
    }

    [Fact]
    public async Task Feed_Requires_Authentication()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();

        var res = await c.GetAsync("/api/posts");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Non_Admin_Cannot_Access_Admin_Reports()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "a@t.com");

        var res = await c.SendAsync(Req(HttpMethod.Get, "/api/admin/reports", teacher));
        Assert.Equal(HttpStatusCode.Forbidden, res.StatusCode);
    }

    [Fact]
    public async Task Like_Notifies_The_Post_Author()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var liker = await RegisterTeacherAsync(c, "liker@t.com");

        var postId = await CreatePostAsync(c, author, "Fractions worksheet");

        var like = await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{postId}/like", liker));
        Assert.Equal(HttpStatusCode.NoContent, like.StatusCode);
        // Idempotent — a repeat like adds no second notification.
        await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{postId}/like", liker));

        var notifs = await c.SendAsync(Req(HttpMethod.Get, "/api/notifications", author));
        var list = await notifs.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, list.GetArrayLength());
        Assert.Equal("PostLiked", list[0].GetProperty("type").GetString());

        var count = await c.SendAsync(Req(HttpMethod.Get, "/api/notifications/unread-count", author));
        var cj = await count.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, cj.GetProperty("count").GetInt32());
    }

    [Fact]
    public async Task Self_Like_Creates_No_Notification()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var postId = await CreatePostAsync(c, author, "Mine");

        await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{postId}/like", author));

        var count = await c.SendAsync(Req(HttpMethod.Get, "/api/notifications/unread-count", author));
        var cj = await count.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(0, cj.GetProperty("count").GetInt32());
    }

    [Fact]
    public async Task MarkAllRead_Clears_Unread_Count()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var other = await RegisterTeacherAsync(c, "other@t.com");
        var postId = await CreatePostAsync(c, author, "Hi");
        await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{postId}/like", other));

        await c.SendAsync(Req(HttpMethod.Post, "/api/notifications/read-all", author));

        var count = await c.SendAsync(Req(HttpMethod.Get, "/api/notifications/unread-count", author));
        var cj = await count.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(0, cj.GetProperty("count").GetInt32());
    }

    [Fact]
    public async Task Presign_Then_Confirm_Registers_A_File()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var presign = await c.SendAsync(Req(HttpMethod.Post, "/api/files/presign", token,
            new { fileName = "photo.png", contentType = "image/png" }));
        presign.EnsureSuccessStatusCode();
        var pj = await presign.Content.ReadFromJsonAsync<JsonElement>();
        var key = pj.GetProperty("key").GetString()!;
        Assert.Contains("uploads/", key);
        Assert.False(string.IsNullOrWhiteSpace(pj.GetProperty("uploadUrl").GetString()));

        // Confirm before the object "exists" → rejected.
        var early = await c.SendAsync(Req(HttpMethod.Post, "/api/files/confirm", token,
            new { key, fileName = "photo.png", contentType = "image/png" }));
        Assert.Equal(HttpStatusCode.BadRequest, early.StatusCode);

        // Pretend the client uploaded it, then confirm → FileObject.
        factory.Storage.Seed(key, 1234);
        var ok = await c.SendAsync(Req(HttpMethod.Post, "/api/files/confirm", token,
            new { key, fileName = "photo.png", contentType = "image/png" }));
        ok.EnsureSuccessStatusCode();
        var fj = await ok.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1234, fj.GetProperty("size").GetInt64());
    }

    [Fact]
    public async Task Confirm_Rejects_A_Foreign_Key()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");
        factory.Storage.Seed("uploads/999999/x.png", 10);

        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/files/confirm", token,
            new { key = "uploads/999999/x.png", fileName = "x.png", contentType = "image/png" }));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Report_Then_Admin_Removes_Content()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var reporter = await RegisterTeacherAsync(c, "reporter@t.com");
        var admin = await CreateAdminAndLoginAsync(factory, c, "admin@t.com");

        var postId = await CreatePostAsync(c, author, "spammy content");

        var report = await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{postId}/report", reporter,
            new { reason = "spam" }));
        Assert.Equal(HttpStatusCode.NoContent, report.StatusCode);

        // Admin sees the open report.
        var open = await c.SendAsync(Req(HttpMethod.Get, "/api/admin/reports?resolved=false", admin));
        var reports = await open.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, reports.GetArrayLength());
        var reportId = reports[0].GetProperty("id").GetInt32();
        Assert.Equal("Post", reports[0].GetProperty("targetType").GetString());

        // Admin removes the content.
        var remove = await c.SendAsync(Req(HttpMethod.Post, $"/api/admin/reports/{reportId}/remove", admin));
        Assert.Equal(HttpStatusCode.NoContent, remove.StatusCode);

        // The post is gone.
        var get = await c.SendAsync(Req(HttpMethod.Get, $"/api/posts/{postId}", author));
        Assert.Equal(HttpStatusCode.NotFound, get.StatusCode);

        // And the report is now resolved.
        var openAfter = await c.SendAsync(Req(HttpMethod.Get, "/api/admin/reports?resolved=false", admin));
        var afterList = await openAfter.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(0, afterList.GetArrayLength());
    }

    [Fact]
    public async Task Admin_Can_List_Users()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "t@t.com");
        var admin = await CreateAdminAndLoginAsync(factory, c, "admin@t.com");

        var res = await c.SendAsync(Req(HttpMethod.Get, "/api/admin/users", admin));
        res.EnsureSuccessStatusCode();
        var users = await res.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(users.GetArrayLength() >= 2); // the teacher + the admin
    }
}
