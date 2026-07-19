using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Models;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// Covers the admin dashboard surface: platform stats, the paginated/searchable
/// user roster, ban/unban, role changes, and that non-admins are locked out.
public class AdminTests
{
    private static HttpRequestMessage Req(HttpMethod method, string url, string token, object? body = null)
    {
        var req = new HttpRequestMessage(method, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null) req.Content = JsonContent.Create(body);
        return req;
    }

    private static async Task<string> RegisterTeacherAsync(HttpClient c, string email)
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
        return json.GetProperty("token").GetString()!;
    }

    /// Seeds an admin account directly (there is no admin self-registration) and
    /// returns a signed-in bearer token for it.
    private static async Task<string> SeedAdminAndLoginAsync(TestApiFactory factory, HttpClient c)
    {
        const string email = "admin@t.com";
        const string password = "adminpass1";
        await factory.WithDbAsync(async db =>
        {
            var admin = new User { Email = email, Role = UserRole.Admin };
            admin.PasswordHash = new PasswordHasher<User>().HashPassword(admin, password);
            db.Users.Add(admin);
            await db.SaveChangesAsync();
        });

        var res = await c.PostAsJsonAsync("/api/v1/auth/login", new { email, password });
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Admin", json.GetProperty("role").GetString());
        return json.GetProperty("token").GetString()!;
    }

    [Fact]
    public async Task Stats_Reports_Platform_Totals_And_Time_Series()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "t1@t.com");
        await RegisterTeacherAsync(c, "t2@t.com");
        var admin = await SeedAdminAndLoginAsync(factory, c);

        var res = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/admin/stats", admin));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();

        var stats = json.GetProperty("stats");
        Assert.Equal(3, stats.GetProperty("totalUsers").GetInt32());   // 2 teachers + admin
        Assert.Equal(2, stats.GetProperty("totalTeachers").GetInt32());
        Assert.Equal(1, stats.GetProperty("totalAdmins").GetInt32());
        Assert.Equal(3, stats.GetProperty("newUsersLast7Days").GetInt32()); // 2 teachers + admin

        // 30 continuous, zero-filled daily points for each series.
        Assert.Equal(30, json.GetProperty("signups").GetArrayLength());
        Assert.Equal(30, json.GetProperty("posts").GetArrayLength());
        // Today's bucket (last point) holds all three fresh signups.
        var lastSignup = json.GetProperty("signups")[29];
        Assert.Equal(3, lastSignup.GetProperty("count").GetInt32());
    }

    [Fact]
    public async Task Users_List_Paginates_And_Searches()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "alice@t.com");
        await RegisterTeacherAsync(c, "bob@t.com");
        var admin = await SeedAdminAndLoginAsync(factory, c);

        // Page 1 with a small page size.
        var page1 = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/admin/users?page=1&pageSize=2", admin));
        page1.EnsureSuccessStatusCode();
        var j1 = await page1.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(3, j1.GetProperty("total").GetInt32());
        Assert.Equal(2, j1.GetProperty("items").GetArrayLength());

        // Search by email narrows to one.
        var search = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/admin/users?search=alice", admin));
        search.EnsureSuccessStatusCode();
        var js = await search.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, js.GetProperty("total").GetInt32());
        Assert.Equal("alice@t.com", js.GetProperty("items")[0].GetProperty("email").GetString());
    }

    [Fact]
    public async Task Ban_Then_Unban_Toggles_Soft_Delete()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "victim@t.com");
        var admin = await SeedAdminAndLoginAsync(factory, c);

        int victimId = 0;
        await factory.WithDbAsync(async db =>
            victimId = (await db.Users.FirstAsync(u => u.Email == "victim@t.com")).Id);

        var ban = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/admin/users/{victimId}/ban", admin));
        Assert.Equal(HttpStatusCode.NoContent, ban.StatusCode);

        // Banned user shows up in the roster flagged as banned...
        var list = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/admin/users?search=victim", admin));
        var jl = await list.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(jl.GetProperty("items")[0].GetProperty("isBanned").GetBoolean());

        // ...and can no longer log in.
        var login = await c.PostAsJsonAsync("/api/v1/auth/login",
            new { email = "victim@t.com", password = "pass1234" });
        Assert.Equal(HttpStatusCode.Unauthorized, login.StatusCode);

        var unban = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/admin/users/{victimId}/unban", admin));
        Assert.Equal(HttpStatusCode.NoContent, unban.StatusCode);

        var loginAgain = await c.PostAsJsonAsync("/api/v1/auth/login",
            new { email = "victim@t.com", password = "pass1234" });
        loginAgain.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Admin_Cannot_Ban_Self_Or_Another_Admin()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var admin = await SeedAdminAndLoginAsync(factory, c);

        int adminId = 0;
        await factory.WithDbAsync(async db =>
            adminId = (await db.Users.FirstAsync(u => u.Email == "admin@t.com")).Id);

        var banSelf = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/admin/users/{adminId}/ban", admin));
        Assert.Equal(HttpStatusCode.BadRequest, banSelf.StatusCode);
    }

    [Fact]
    public async Task Change_Role_Promotes_A_Teacher()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "promote@t.com");
        var admin = await SeedAdminAndLoginAsync(factory, c);

        int userId = 0;
        await factory.WithDbAsync(async db =>
            userId = (await db.Users.FirstAsync(u => u.Email == "promote@t.com")).Id);

        var res = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/admin/users/{userId}/role", admin,
            new { role = "Admin" }));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Admin", json.GetProperty("role").GetString());
    }

    [Fact]
    public async Task Admin_Cannot_Demote_Self()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var admin = await SeedAdminAndLoginAsync(factory, c);

        int adminId = 0;
        await factory.WithDbAsync(async db =>
            adminId = (await db.Users.FirstAsync(u => u.Email == "admin@t.com")).Id);

        var res = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/admin/users/{adminId}/role", admin,
            new { role = "Teacher" }));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Non_Admin_Is_Forbidden_From_Admin_Routes()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "teacher@t.com");

        var stats = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/admin/stats", teacher));
        Assert.Equal(HttpStatusCode.Forbidden, stats.StatusCode);

        var users = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/admin/users", teacher));
        Assert.Equal(HttpStatusCode.Forbidden, users.StatusCode);
    }
}
