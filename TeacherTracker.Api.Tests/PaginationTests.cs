using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace TeacherTracker.Api.Tests;

public class PaginationTests
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

    private static async Task<int> CreateStudentAsync(HttpClient c, string token, int n)
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", token, new
        {
            firstName = $"Student{n}",
            lastName = "Test",
            studentNumber = $"S{n}",
        }));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("id").GetInt32();
    }

    private static async Task<int> CreateClassroomAsync(HttpClient c, string token, int n)
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/classrooms", token, new { name = $"Class{n}" }));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("id").GetInt32();
    }

    private static async Task<List<int>> GetIdsAsync(HttpClient c, string url, string token)
    {
        var res = await c.SendAsync(Req(HttpMethod.Get, url, token));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.EnumerateArray().Select(e => e.GetProperty("id").GetInt32()).ToList();
    }

    [Fact]
    public async Task Students_Paginate_By_BeforeId_And_Limit()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var ids = new List<int>();
        for (var i = 0; i < 25; i++) ids.Add(await CreateStudentAsync(c, token, i));
        ids.Reverse(); // newest (highest id) first, matching OrderByDescending(Id)

        var page1 = await GetIdsAsync(c, "/api/v1/students?limit=10", token);
        Assert.Equal(ids.Take(10), page1);

        var page2 = await GetIdsAsync(c, $"/api/v1/students?limit=10&beforeId={page1[^1]}", token);
        Assert.Equal(ids.Skip(10).Take(10), page2);
        Assert.Empty(page1.Intersect(page2));

        // limit is clamped to [1, 50].
        var overLimit = await GetIdsAsync(c, "/api/v1/students?limit=999", token);
        Assert.Equal(25, overLimit.Count);
    }

    [Fact]
    public async Task Classrooms_Paginate_By_BeforeId_And_Limit()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var ids = new List<int>();
        for (var i = 0; i < 25; i++) ids.Add(await CreateClassroomAsync(c, token, i));
        ids.Reverse();

        var page1 = await GetIdsAsync(c, "/api/v1/classrooms?limit=10", token);
        Assert.Equal(ids.Take(10), page1);

        var page2 = await GetIdsAsync(c, $"/api/v1/classrooms?limit=10&beforeId={page1[^1]}", token);
        Assert.Equal(ids.Skip(10).Take(10), page2);
        Assert.Empty(page1.Intersect(page2));
    }

    [Fact]
    public async Task Homework_Paginates_By_BeforeId_And_Limit()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");
        var studentId = await CreateStudentAsync(c, token, 0);

        var ids = new List<int>();
        for (var i = 0; i < 25; i++)
        {
            var res = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/students/{studentId}/homework", token,
                new { title = $"HW{i}", description = "d", isDone = false }));
            res.EnsureSuccessStatusCode();
            var json = await res.Content.ReadFromJsonAsync<JsonElement>();
            ids.Add(json.GetProperty("id").GetInt32());
        }
        ids.Reverse();

        var page1 = await GetIdsAsync(c, $"/api/v1/students/{studentId}/homework?limit=10", token);
        Assert.Equal(ids.Take(10), page1);

        var page2 = await GetIdsAsync(c,
            $"/api/v1/students/{studentId}/homework?limit=10&beforeId={page1[^1]}", token);
        Assert.Equal(ids.Skip(10).Take(10), page2);
        Assert.Empty(page1.Intersect(page2));
    }

    [Fact]
    public async Task Books_Paginate_By_BeforeId_And_Limit()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");
        var studentId = await CreateStudentAsync(c, token, 0);

        var ids = new List<int>();
        for (var i = 0; i < 25; i++)
        {
            var res = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/students/{studentId}/books", token,
                new { title = $"Book{i}", author = "Author", status = "Reading" }));
            res.EnsureSuccessStatusCode();
            var json = await res.Content.ReadFromJsonAsync<JsonElement>();
            ids.Add(json.GetProperty("id").GetInt32());
        }
        ids.Reverse();

        var page1 = await GetIdsAsync(c, $"/api/v1/students/{studentId}/books?limit=10", token);
        Assert.Equal(ids.Take(10), page1);

        var page2 = await GetIdsAsync(c,
            $"/api/v1/students/{studentId}/books?limit=10&beforeId={page1[^1]}", token);
        Assert.Equal(ids.Skip(10).Take(10), page2);
        Assert.Empty(page1.Intersect(page2));
    }

    [Fact]
    public async Task Notifications_Paginate_By_BeforeId_And_Limit()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var liker = await RegisterTeacherAsync(c, "liker@t.com");

        var postIds = new List<int>();
        for (var i = 0; i < 25; i++)
        {
            var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/posts", author,
                new { text = $"Post {i}", subject = "Math" }));
            res.EnsureSuccessStatusCode();
            var json = await res.Content.ReadFromJsonAsync<JsonElement>();
            postIds.Add(json.GetProperty("id").GetInt32());
        }
        // Each like creates one notification for the author, in the same order.
        foreach (var postId in postIds)
            await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/posts/{postId}/like", liker));

        var page1 = await GetIdsAsync(c, "/api/v1/notifications?limit=10", author);
        Assert.Equal(10, page1.Count);

        var page2 = await GetIdsAsync(c, $"/api/v1/notifications?limit=10&beforeId={page1[^1]}", author);
        Assert.Equal(10, page2.Count);
        Assert.Empty(page1.Intersect(page2));
        Assert.All(page2, id => Assert.True(id < page1[^1]));
    }
}
