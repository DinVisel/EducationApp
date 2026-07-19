using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// Covers the hybrid student onboarding flows: Method A (teacher-driven Access
/// Card, passwordless login) and Method B (student-driven Class Code + Waiting
/// Lobby approval).
public class OnboardingTests
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
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("token").GetString()!;
    }

    private static async Task<(string token, int classroomId, string classCode)> CreateClassAsync(
        HttpClient c, string teacherToken, string name = "Math 101")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/classrooms", teacherToken, new { name }));
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        return (teacherToken, json.GetProperty("id").GetInt32(), json.GetProperty("classCode").GetString()!);
    }

    // ── Method A: Access Card ───────────────────────────────────────────────

    [Fact]
    public async Task Teacher_Bulk_Creates_Access_Cards_With_Unique_Codes()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, _) = await CreateClassAsync(c, teacher);

        var res = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/access-cards", teacher,
            new { names = new[] { "Ada Lovelace", "Alan Turing", "Grace Hopper" } }));
        res.EnsureSuccessStatusCode();
        var cards = await res.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(3, cards.GetArrayLength());
        var codes = cards.EnumerateArray().Select(x => x.GetProperty("accessCode").GetString()).ToList();
        Assert.Equal(3, codes.Distinct().Count());
        // QR token is returned once at creation.
        Assert.All(cards.EnumerateArray(), x =>
            Assert.False(string.IsNullOrEmpty(x.GetProperty("qrToken").GetString())));
        // Name splitting: last token is the surname.
        Assert.Contains(cards.EnumerateArray(), x =>
            x.GetProperty("firstName").GetString() == "Ada" &&
            x.GetProperty("lastName").GetString() == "Lovelace");
    }

    [Fact]
    public async Task Access_Card_Student_Logs_In_With_Code_And_Is_Enrolled()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, _) = await CreateClassAsync(c, teacher);

        var create = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/access-cards", teacher,
            new { names = new[] { "Ada Lovelace" } }));
        var card = (await create.Content.ReadFromJsonAsync<JsonElement>())[0];
        var code = card.GetProperty("accessCode").GetString()!;

        // Passwordless login with the code.
        var login = await c.PostAsJsonAsync("/api/v1/auth/access-code", new { code });
        login.EnsureSuccessStatusCode();
        var session = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Student", session.GetProperty("role").GetString());
        var studentToken = session.GetProperty("token").GetString()!;

        // The access-card student is enrolled immediately (no lobby).
        var classes = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/classes", studentToken));
        classes.EnsureSuccessStatusCode();
        var list = await classes.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, list.GetArrayLength());
    }

    [Fact]
    public async Task Access_Card_Student_Logs_In_With_Qr_Token()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, _) = await CreateClassAsync(c, teacher);
        var create = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/access-cards", teacher,
            new { names = new[] { "Ada Lovelace" } }));
        var qr = (await create.Content.ReadFromJsonAsync<JsonElement>())[0]
            .GetProperty("qrToken").GetString()!;

        var login = await c.PostAsJsonAsync("/api/v1/auth/access-qr", new { token = qr });
        login.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Rotate_Access_Card_Invalidates_Old_Code()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, _) = await CreateClassAsync(c, teacher);
        var create = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/access-cards", teacher,
            new { names = new[] { "Ada Lovelace" } }));
        var card = (await create.Content.ReadFromJsonAsync<JsonElement>())[0];
        var studentId = card.GetProperty("studentId").GetInt32();
        var oldCode = card.GetProperty("accessCode").GetString()!;

        var rotate = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/access-cards/{studentId}/rotate", teacher));
        rotate.EnsureSuccessStatusCode();
        var newCode = (await rotate.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("accessCode").GetString()!;
        Assert.NotEqual(oldCode, newCode);

        // Old code no longer works; new one does.
        var oldLogin = await c.PostAsJsonAsync("/api/v1/auth/access-code", new { code = oldCode });
        Assert.Equal(HttpStatusCode.Unauthorized, oldLogin.StatusCode);
        var newLogin = await c.PostAsJsonAsync("/api/v1/auth/access-code", new { code = newCode });
        newLogin.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Invalid_Access_Code_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var res = await c.PostAsJsonAsync("/api/v1/auth/access-code", new { code = "ZZZZZZ" });
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    // ── Method B: Class Code & Lobby ────────────────────────────────────────

    private static async Task<string> RegisterStudentAsync(HttpClient c, string email)
    {
        var res = await c.PostAsJsonAsync("/api/v1/auth/register", new
        {
            firstName = "Self",
            lastName = "Student",
            email,
            password = "pass1234",
            role = "Student",
        });
        res.EnsureSuccessStatusCode();
        var json = await res.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Student", json.GetProperty("role").GetString());
        return json.GetProperty("token").GetString()!;
    }

    [Fact]
    public async Task Student_Join_Request_Goes_To_Lobby_Not_Enrollment()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, classCode) = await CreateClassAsync(c, teacher);
        var student = await RegisterStudentAsync(c, "s@s.com");

        var join = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests",
            student, new { classCode }));
        join.EnsureSuccessStatusCode();
        Assert.Equal("Pending",
            (await join.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("status").GetString());

        // Not yet enrolled.
        var classes = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/classes", student));
        Assert.Equal(0, (await classes.Content.ReadFromJsonAsync<JsonElement>()).GetArrayLength());

        // Shows up in the teacher's lobby.
        var lobby = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classroomId}/join-requests", teacher));
        Assert.Equal(1, (await lobby.Content.ReadFromJsonAsync<JsonElement>()).GetArrayLength());
    }

    [Fact]
    public async Task Teacher_Approval_Enrolls_The_Student()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, classCode) = await CreateClassAsync(c, teacher);
        var student = await RegisterStudentAsync(c, "s@s.com");
        await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests", student, new { classCode }));

        var lobby = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classroomId}/join-requests", teacher));
        var requestId = (await lobby.Content.ReadFromJsonAsync<JsonElement>())[0]
            .GetProperty("requestId").GetInt32();

        var approve = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/join-requests/{requestId}/approve", teacher));
        approve.EnsureSuccessStatusCode();

        // Now enrolled.
        var classes = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/classes", student));
        Assert.Equal(1, (await classes.Content.ReadFromJsonAsync<JsonElement>()).GetArrayLength());

        // Lobby is now empty.
        var lobby2 = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classroomId}/join-requests", teacher));
        Assert.Equal(0, (await lobby2.Content.ReadFromJsonAsync<JsonElement>()).GetArrayLength());
    }

    [Fact]
    public async Task Teacher_Rejection_Does_Not_Enroll_But_Allows_Re_Request()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, classroomId, classCode) = await CreateClassAsync(c, teacher);
        var student = await RegisterStudentAsync(c, "s@s.com");
        await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests", student, new { classCode }));

        var lobby = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classroomId}/join-requests", teacher));
        var requestId = (await lobby.Content.ReadFromJsonAsync<JsonElement>())[0]
            .GetProperty("requestId").GetInt32();
        var reject = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/join-requests/{requestId}/reject", teacher));
        reject.EnsureSuccessStatusCode();

        var classes = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/classes", student));
        Assert.Equal(0, (await classes.Content.ReadFromJsonAsync<JsonElement>()).GetArrayLength());

        // A rejected student can submit a fresh request.
        var reJoin = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests",
            student, new { classCode }));
        reJoin.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Duplicate_Pending_Request_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var (_, _, classCode) = await CreateClassAsync(c, teacher);
        var student = await RegisterStudentAsync(c, "s@s.com");

        var first = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests",
            student, new { classCode }));
        first.EnsureSuccessStatusCode();
        var second = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests",
            student, new { classCode }));
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task Unknown_Class_Code_Returns_NotFound()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "t@t.com");
        var student = await RegisterStudentAsync(c, "s@s.com");

        var join = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests",
            student, new { classCode = "NOPE00" }));
        Assert.Equal(HttpStatusCode.NotFound, join.StatusCode);
    }

    [Fact]
    public async Task Student_From_Another_Teachers_Class_Cannot_Be_Approved_By_Wrong_Teacher()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacherA = await RegisterTeacherAsync(c, "a@t.com");
        var teacherB = await RegisterTeacherAsync(c, "b@t.com");
        var (_, classroomId, classCode) = await CreateClassAsync(c, teacherA);
        var student = await RegisterStudentAsync(c, "s@s.com");
        await c.SendAsync(Req(HttpMethod.Post, "/api/v1/student/class-requests", student, new { classCode }));

        // Teacher B can't see or act on teacher A's class lobby.
        var lobby = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classroomId}/join-requests", teacherB));
        Assert.Equal(HttpStatusCode.NotFound, lobby.StatusCode);
    }
}
