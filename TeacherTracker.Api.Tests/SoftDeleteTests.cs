using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace TeacherTracker.Api.Tests;

public class SoftDeleteTests
{
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

    private static HttpRequestMessage Req(HttpMethod method, string url, string token, object? body = null)
    {
        var req = new HttpRequestMessage(method, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null) req.Content = JsonContent.Create(body);
        return req;
    }

    [Fact]
    public async Task Deleting_A_Student_Hides_It_But_Keeps_The_Row()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var create = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", token,
            new { firstName = "Ada", lastName = "Lovelace", studentNumber = "S1" }));
        create.EnsureSuccessStatusCode();
        var studentId = (await create.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("id").GetInt32();

        var delete = await c.SendAsync(Req(HttpMethod.Delete, $"/api/v1/students/{studentId}", token));
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var getAfter = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/students/{studentId}", token));
        Assert.Equal(HttpStatusCode.NotFound, getAfter.StatusCode);

        await factory.WithDbAsync(async db =>
        {
            var student = await db.Students.IgnoreQueryFilters()
                .FirstAsync(s => s.Id == studentId);
            Assert.True(student.IsDeleted);
            Assert.NotNull(student.DeletedAt);
        });
    }

    [Fact]
    public async Task Deleting_A_Post_Hides_It_But_Keeps_Comments_And_Likes()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var other = await RegisterTeacherAsync(c, "other@t.com");

        var create = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/posts", author,
            new { text = "hello", subject = "Math" }));
        create.EnsureSuccessStatusCode();
        var postId = (await create.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("id").GetInt32();

        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/posts/{postId}/like", other));
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/posts/{postId}/comments", other,
            new { text = "nice!" }));

        var delete = await c.SendAsync(Req(HttpMethod.Delete, $"/api/v1/posts/{postId}", author));
        Assert.Equal(HttpStatusCode.NoContent, delete.StatusCode);

        var getAfter = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/posts/{postId}", author));
        Assert.Equal(HttpStatusCode.NotFound, getAfter.StatusCode);

        await factory.WithDbAsync(async db =>
        {
            var post = await db.Posts.IgnoreQueryFilters().FirstAsync(p => p.Id == postId);
            Assert.True(post.IsDeleted);
            Assert.NotNull(post.DeletedAt);

            Assert.Equal(1, await db.PostLikes.CountAsync(l => l.PostId == postId));
            Assert.Equal(1, await db.PostComments.CountAsync(cm => cm.PostId == postId));
        });
    }

    [Fact]
    public async Task Revoking_A_Student_Account_Soft_Deletes_The_User_Not_Removes_It()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var create = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", token,
            new { firstName = "Ada", lastName = "Lovelace", studentNumber = "S1" }));
        create.EnsureSuccessStatusCode();
        var studentId = (await create.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("id").GetInt32();

        var account = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/students/{studentId}/account", token,
            new { email = "ada@students.local", password = "pass1234" }));
        account.EnsureSuccessStatusCode();

        var revoke = await c.SendAsync(Req(HttpMethod.Delete, $"/api/v1/students/{studentId}/account", token));
        Assert.Equal(HttpStatusCode.NoContent, revoke.StatusCode);

        var accountAfter = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/students/{studentId}/account", token));
        accountAfter.EnsureSuccessStatusCode();
        var aj = await accountAfter.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(aj.GetProperty("hasAccount").GetBoolean());

        await factory.WithDbAsync(async db =>
        {
            var user = await db.Users.IgnoreQueryFilters()
                .FirstAsync(u => u.Email == "ada@students.local");
            Assert.True(user.IsDeleted);
            Assert.NotNull(user.DeletedAt);
        });
    }

    [Fact]
    public async Task Creating_A_Student_Records_Who_Created_It()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var session = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/auth/session", token));
        session.EnsureSuccessStatusCode();
        var myUserId = (await session.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("teacher").GetProperty("userId").GetInt32();

        var create = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", token,
            new { firstName = "Ada", lastName = "Lovelace", studentNumber = "S1" }));
        create.EnsureSuccessStatusCode();
        var studentId = (await create.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("id").GetInt32();

        await factory.WithDbAsync(async db =>
        {
            var student = await db.Students.FirstAsync(s => s.Id == studentId);
            Assert.Equal(myUserId, student.CreatedBy);
        });
    }
}
