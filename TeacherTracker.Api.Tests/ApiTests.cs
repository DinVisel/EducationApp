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

    // The signed-in teacher's account (User) id, via the session endpoint.
    private static async Task<int> MyUserIdAsync(HttpClient c, string token)
    {
        var res = await c.SendAsync(Req(HttpMethod.Get, "/api/auth/session", token));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("teacher").GetProperty("userId").GetInt32();
    }

    // Presign → seed → confirm a file owned by the caller; returns its id.
    private static async Task<int> CreateFileAsync(TestApiFactory factory, HttpClient c, string token)
    {
        var presign = await c.SendAsync(Req(HttpMethod.Post, "/api/files/presign", token,
            new { fileName = "a.png", contentType = "image/png" }));
        presign.EnsureSuccessStatusCode();
        var pj = await presign.Content.ReadFromJsonAsync<JsonElement>();
        var key = pj.GetProperty("key").GetString()!;
        factory.Storage.Seed(key, 10);
        var ok = await c.SendAsync(Req(HttpMethod.Post, "/api/files/confirm", token,
            new { key, fileName = "a.png", contentType = "image/png" }));
        ok.EnsureSuccessStatusCode();
        var fj = await ok.Content.ReadFromJsonAsync<JsonElement>();
        return fj.GetProperty("id").GetInt32();
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
        // Direct uploads land in quarantine; confirm promotes them to uploads/.
        Assert.Contains("quarantine/", key);
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

        // The clean image was promoted out of quarantine into uploads/.
        Assert.False(factory.Storage.Exists(key));
        Assert.True(factory.Storage.Exists(key.Replace("quarantine/", "uploads/")));
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
    public async Task Pin_Is_Author_Only_And_Sorts_Profile_Posts_First()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var authorUid = await MyUserIdAsync(c, author);
        var other = await RegisterTeacherAsync(c, "other@t.com");

        var p1 = await CreatePostAsync(c, author, "first");
        var p2 = await CreatePostAsync(c, author, "second"); // newest

        // Author pins the older post.
        var pin = await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{p1}/pin", author));
        Assert.Equal(HttpStatusCode.NoContent, pin.StatusCode);

        // A non-author cannot pin someone else's post → 404 (doesn't reveal it).
        var badPin = await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{p2}/pin", other));
        Assert.Equal(HttpStatusCode.NotFound, badPin.StatusCode);

        // The author's profile lists the pinned post first, even though it's older.
        var res = await c.SendAsync(Req(HttpMethod.Get, $"/api/posts?authorUserId={authorUid}", other));
        res.EnsureSuccessStatusCode();
        var list = await res.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(2, list.GetArrayLength());
        Assert.Equal(p1, list[0].GetProperty("id").GetInt32());
        Assert.True(list[0].GetProperty("isPinned").GetBoolean());
    }

    [Fact]
    public async Task Profile_Image_Is_Viewable_By_Other_Teachers()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var a = await RegisterTeacherAsync(c, "a@t.com");
        var b = await RegisterTeacherAsync(c, "b@t.com");

        var fileId = await CreateFileAsync(factory, c, a);

        // Before it's a profile image, B can't fetch A's file.
        var before = await c.SendAsync(Req(HttpMethod.Get, $"/api/files/{fileId}", b));
        Assert.Equal(HttpStatusCode.NotFound, before.StatusCode);

        // A sets it as their avatar.
        var upd = await c.SendAsync(Req(HttpMethod.Put, "/api/auth/me", a,
            new { firstName = "A", lastName = "T", email = "a@t.com", avatarFileId = fileId }));
        upd.EnsureSuccessStatusCode();
        var uj = await upd.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(fileId, uj.GetProperty("avatarFileId").GetInt32());

        // Now B can fetch it (profiles are cross-viewable).
        var after = await c.SendAsync(Req(HttpMethod.Get, $"/api/files/{fileId}", b));
        Assert.Equal(HttpStatusCode.OK, after.StatusCode);
    }

    [Fact]
    public async Task UpdateProfile_Rejects_A_Foreign_Avatar_File()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var a = await RegisterTeacherAsync(c, "a@t.com");
        var b = await RegisterTeacherAsync(c, "b@t.com");
        var bFile = await CreateFileAsync(factory, c, b);

        var res = await c.SendAsync(Req(HttpMethod.Put, "/api/auth/me", a,
            new { firstName = "A", lastName = "T", email = "a@t.com", avatarFileId = bFile }));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
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

    // --- Phase 9: content safety ----------------------------------------------

    [Fact]
    public async Task Confirm_Rejects_A_Flagged_Image_And_Deletes_It()
    {
        using var factory = new TestApiFactory();
        factory.ImageModerator.Flagged = true; // Rekognition would flag this image
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        var presign = await c.SendAsync(Req(HttpMethod.Post, "/api/files/presign", token,
            new { fileName = "bad.png", contentType = "image/png" }));
        presign.EnsureSuccessStatusCode();
        var key = (await presign.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("key").GetString()!;
        factory.Storage.Seed(key, 1234);

        var confirm = await c.SendAsync(Req(HttpMethod.Post, "/api/files/confirm", token,
            new { key, fileName = "bad.png", contentType = "image/png" }));

        // Rejected 422, purged from R2, and never recorded / promoted.
        Assert.Equal(HttpStatusCode.UnprocessableEntity, confirm.StatusCode);
        Assert.False(factory.Storage.Exists(key));
        Assert.False(factory.Storage.Exists(key.Replace("quarantine/", "uploads/")));
    }

    [Fact]
    public async Task Proxy_Upload_Rejects_A_Flagged_Image()
    {
        using var factory = new TestApiFactory();
        factory.ImageModerator.Flagged = true;
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        using var content = new MultipartFormDataContent();
        var bytes = new ByteArrayContent(new byte[] { 1, 2, 3, 4 });
        bytes.Headers.ContentType = new MediaTypeHeaderValue("image/png");
        content.Add(bytes, "file", "bad.png");

        var req = new HttpRequestMessage(HttpMethod.Post, "/api/files") { Content = content };
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var res = await c.SendAsync(req);

        Assert.Equal(HttpStatusCode.UnprocessableEntity, res.StatusCode);
    }

    [Fact]
    public async Task Post_With_Profanity_Is_Rejected_And_Clean_Text_Passes()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");

        // A blocked term (even lightly obfuscated) is rejected 422.
        var bad = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", token,
            new { text = "you are a f.u.c.k", subject = "Math" }));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, bad.StatusCode);

        // Clean text is accepted.
        var ok = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", token,
            new { text = "great work everyone", subject = "Math" }));
        Assert.Equal(HttpStatusCode.Created, ok.StatusCode);
    }

    [Fact]
    public async Task Comment_With_Profanity_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "a@t.com");
        var postId = await CreatePostAsync(c, token, "clean post");

        var res = await c.SendAsync(Req(HttpMethod.Post, $"/api/posts/{postId}/comments", token,
            new { text = "this is shit" }));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, res.StatusCode);
    }
}
