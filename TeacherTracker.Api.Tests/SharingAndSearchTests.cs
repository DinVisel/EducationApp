using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// Coverage for quiz sharing to the feed (share + rate + clone) and global
/// discovery search (teachers + materials with filters).
public class SharingAndSearchTests
{
    // --- helpers ---------------------------------------------------------------

    private static async Task<string> RegisterTeacherAsync(
        HttpClient c, string email, string first = "Test", string last = "Teacher")
    {
        var res = await c.PostAsJsonAsync("/api/auth/register", new
        {
            firstName = first,
            lastName = last,
            email,
            password = "pass1234",
        });
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("token").GetString()!;
    }

    private static HttpRequestMessage Req(HttpMethod method, string url, string token, object? body = null)
    {
        var req = new HttpRequestMessage(method, url);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        if (body is not null) req.Content = JsonContent.Create(body);
        return req;
    }

    private static async Task<int> CreateClassroomAsync(HttpClient c, string token, string name = "Class A")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/classrooms", token, new { name }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    private static async Task<int> CreateStudentAsync(HttpClient c, string token, string first = "Sam")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/students", token, new
        {
            firstName = first,
            lastName = "Student",
            studentNumber = "001",
        }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    private static object SampleQuiz(string title = "Photosynthesis Basics") => new
    {
        title,
        description = "Plants and light",
        category = "Practice",
        questions = new object[]
        {
            new
            {
                text = "What do plants need?",
                choices = new object[]
                {
                    new { text = "Sunlight", isCorrect = true },
                    new { text = "Darkness", isCorrect = false },
                },
            },
        },
    };

    private static async Task<int> CreateQuizAsync(HttpClient c, string token, int classroomId, object? quiz = null)
    {
        var res = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/classrooms/{classroomId}/quizzes", token, quiz ?? SampleQuiz()));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    // Shares a quiz to the feed; returns the created post id.
    private static async Task<int> ShareQuizAsync(
        HttpClient c, string token, int quizId,
        string subject = "Science", string grade = "Grade3", string text = "Check out my quiz!")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", token, new
        {
            text,
            subject,
            gradeLevel = grade,
            sharedQuizId = quizId,
        }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    private static async Task<int> SeedPdfFileAsync(TestApiFactory factory, HttpClient c, string token, string name)
    {
        var presign = await c.SendAsync(Req(HttpMethod.Post, "/api/files/presign", token,
            new { fileName = name, contentType = "application/pdf" }));
        presign.EnsureSuccessStatusCode();
        var key = (await presign.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("key").GetString()!;
        factory.Storage.Seed(key, 2048);
        var ok = await c.SendAsync(Req(HttpMethod.Post, "/api/files/confirm", token,
            new { key, fileName = name, contentType = "application/pdf" }));
        ok.EnsureSuccessStatusCode();
        return (await ok.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    // --- sharing + rating ------------------------------------------------------

    [Fact]
    public async Task Shared_Quiz_Appears_On_The_Post_With_Preview()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);
        var quizId = await CreateQuizAsync(c, teacher, classId);
        var postId = await ShareQuizAsync(c, teacher, quizId);

        var get = await c.SendAsync(Req(HttpMethod.Get, $"/api/posts/{postId}", teacher));
        get.EnsureSuccessStatusCode();
        var p = await get.Content.ReadFromJsonAsync<JsonElement>();
        var shared = p.GetProperty("sharedQuiz");
        Assert.Equal(quizId, shared.GetProperty("quizId").GetInt32());
        Assert.Equal(1, shared.GetProperty("questionCount").GetInt32());
        Assert.Equal(0, p.GetProperty("ratingCount").GetInt32());
        Assert.Equal("Grade3", p.GetProperty("gradeLevel").GetString());
    }

    [Fact]
    public async Task Rating_A_Shared_Quiz_Reflects_In_Post()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var rater = await RegisterTeacherAsync(c, "rater@t.com");
        var classId = await CreateClassroomAsync(c, author);
        var quizId = await CreateQuizAsync(c, author, classId);
        var postId = await ShareQuizAsync(c, author, quizId);

        var rate = await c.SendAsync(Req(HttpMethod.Put, $"/api/posts/{postId}/rating", rater, new { value = 4 }));
        Assert.Equal(HttpStatusCode.NoContent, rate.StatusCode);
        // Re-rating updates rather than duplicating.
        await c.SendAsync(Req(HttpMethod.Put, $"/api/posts/{postId}/rating", rater, new { value = 5 }));

        var get = await c.SendAsync(Req(HttpMethod.Get, $"/api/posts/{postId}", rater));
        var p = await get.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, p.GetProperty("ratingCount").GetInt32());
        Assert.Equal(5, p.GetProperty("myRating").GetInt32());
        Assert.Equal(5, p.GetProperty("averageRating").GetDouble());

        // Author gets a PostRated notification.
        var notifs = await c.SendAsync(Req(HttpMethod.Get, "/api/notifications", author));
        var list = await notifs.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Contains(list.EnumerateArray(), n => n.GetProperty("type").GetString() == "PostRated");
    }

    [Fact]
    public async Task Rating_A_Non_Quiz_Post_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var post = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", teacher,
            new { text = "just a text post", subject = "General" }));
        var postId = (await post.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();

        var rate = await c.SendAsync(Req(HttpMethod.Put, $"/api/posts/{postId}/rating", teacher, new { value = 3 }));
        Assert.Equal(HttpStatusCode.BadRequest, rate.StatusCode);
    }

    [Fact]
    public async Task Cannot_Share_A_Quiz_You_Dont_Own()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var owner = await RegisterTeacherAsync(c, "owner@t.com");
        var intruder = await RegisterTeacherAsync(c, "intruder@t.com");
        var classId = await CreateClassroomAsync(c, owner);
        var quizId = await CreateQuizAsync(c, owner, classId);

        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", intruder,
            new { text = "not mine", subject = "General", sharedQuizId = quizId }));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    // --- cloning ---------------------------------------------------------------

    [Fact]
    public async Task Clone_Copies_Quiz_And_Fans_Out_To_The_Cloners_Class()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var cloner = await RegisterTeacherAsync(c, "cloner@t.com");

        var aClass = await CreateClassroomAsync(c, author);
        var quizId = await CreateQuizAsync(c, author, aClass);
        await ShareQuizAsync(c, author, quizId);

        // Cloner sets up their own class with two students.
        var bClass = await CreateClassroomAsync(c, cloner, "Cloner Class");
        var s1 = await CreateStudentAsync(c, cloner, "A");
        var s2 = await CreateStudentAsync(c, cloner, "B");
        await c.SendAsync(Req(HttpMethod.Post, $"/api/classrooms/{bClass}/students/{s1}", cloner));
        await c.SendAsync(Req(HttpMethod.Post, $"/api/classrooms/{bClass}/students/{s2}", cloner));

        var clone = await c.SendAsync(Req(HttpMethod.Post, $"/api/quizzes/{quizId}/clone", cloner,
            new { classroomId = bClass }));
        clone.EnsureSuccessStatusCode();
        var cloned = await clone.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(bClass, cloned.GetProperty("classroomId").GetInt32());
        Assert.Equal(2, cloned.GetProperty("assignedCount").GetInt32());

        // The cloned quiz lives under the cloner's class.
        var list = await c.SendAsync(Req(HttpMethod.Get, $"/api/classrooms/{bClass}/quizzes", cloner));
        var quizzes = await list.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, quizzes.GetArrayLength());
        Assert.Equal("Photosynthesis Basics", quizzes[0].GetProperty("title").GetString());

        // The original author is notified their quiz was cloned.
        var notifs = await c.SendAsync(Req(HttpMethod.Get, "/api/notifications", author));
        var notifList = await notifs.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Contains(notifList.EnumerateArray(), n => n.GetProperty("type").GetString() == "QuizCloned");
    }

    [Fact]
    public async Task Unshared_Quiz_Is_Not_Cloneable_Or_Previewable_By_Others()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var owner = await RegisterTeacherAsync(c, "owner@t.com");
        var other = await RegisterTeacherAsync(c, "other@t.com");
        var ownerClass = await CreateClassroomAsync(c, owner);
        var quizId = await CreateQuizAsync(c, owner, ownerClass); // NOT shared
        var otherClass = await CreateClassroomAsync(c, other, "Other Class");

        var preview = await c.SendAsync(Req(HttpMethod.Get, $"/api/quizzes/{quizId}/preview", other));
        Assert.Equal(HttpStatusCode.NotFound, preview.StatusCode);

        var clone = await c.SendAsync(Req(HttpMethod.Post, $"/api/quizzes/{quizId}/clone", other,
            new { classroomId = otherClass }));
        Assert.Equal(HttpStatusCode.NotFound, clone.StatusCode);
    }

    // --- search ----------------------------------------------------------------

    [Fact]
    public async Task Search_Finds_Teachers_By_Name()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        await RegisterTeacherAsync(c, "alice@t.com", "Alice", "Anderson");
        var seeker = await RegisterTeacherAsync(c, "seeker@t.com", "Bob", "Brown");

        var res = await c.SendAsync(Req(HttpMethod.Get, "/api/search?q=Alice&type=teachers", seeker));
        res.EnsureSuccessStatusCode();
        var results = await res.Content.ReadFromJsonAsync<JsonElement>();
        var teachers = results.GetProperty("teachers");
        Assert.Contains(teachers.EnumerateArray(),
            t => t.GetProperty("name").GetString() == "Alice Anderson");
    }

    [Fact]
    public async Task Search_Finds_Shared_Quiz_Materials_With_Filters()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var seeker = await RegisterTeacherAsync(c, "seeker@t.com");
        var classId = await CreateClassroomAsync(c, author);
        var quizId = await CreateQuizAsync(c, author, classId, SampleQuiz("Fractions Fun"));
        await ShareQuizAsync(c, author, quizId, subject: "Math", grade: "Grade4");

        // Matching filter returns the material.
        var hit = await c.SendAsync(Req(HttpMethod.Get,
            "/api/search?q=Fractions&type=quizzes&subject=Math&grade=Grade4", seeker));
        hit.EnsureSuccessStatusCode();
        var hitMaterials = (await hit.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("materials");
        Assert.Equal(1, hitMaterials.GetArrayLength());
        Assert.Equal("Quiz", hitMaterials[0].GetProperty("type").GetString());
        Assert.Equal(quizId, hitMaterials[0].GetProperty("quizId").GetInt32());

        // Non-matching grade filter excludes it.
        var miss = await c.SendAsync(Req(HttpMethod.Get,
            "/api/search?q=Fractions&type=quizzes&subject=Math&grade=Grade1", seeker));
        var missMaterials = (await miss.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("materials");
        Assert.Equal(0, missMaterials.GetArrayLength());
    }

    [Fact]
    public async Task Search_Finds_Shared_Document_Materials()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var author = await RegisterTeacherAsync(c, "author@t.com");
        var seeker = await RegisterTeacherAsync(c, "seeker@t.com");

        var fileId = await SeedPdfFileAsync(factory, c, author, "geometry-worksheet.pdf");
        var post = await c.SendAsync(Req(HttpMethod.Post, "/api/posts", author,
            new { text = "worksheet", subject = "Math", gradeLevel = "Grade5", fileIds = new[] { fileId } }));
        post.EnsureSuccessStatusCode();

        var res = await c.SendAsync(Req(HttpMethod.Get,
            "/api/search?q=geometry&type=documents", seeker));
        res.EnsureSuccessStatusCode();
        var materials = (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("materials");
        Assert.Equal(1, materials.GetArrayLength());
        Assert.Equal("Document", materials[0].GetProperty("type").GetString());
        Assert.Equal(fileId, materials[0].GetProperty("fileId").GetInt32());
    }
}
