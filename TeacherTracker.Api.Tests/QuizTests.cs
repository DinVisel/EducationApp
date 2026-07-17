using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// End-to-end coverage for the quiz feature: teacher authoring + fan-out,
/// ownership scoping, student solving with authoritative server-side grading,
/// single-attempt locking, and analytics.
public class QuizTests
{
    // --- helpers ---------------------------------------------------------------

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

    private static async Task<int> CreateClassroomAsync(HttpClient c, string token, string name = "Class A")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/classrooms", token, new { name }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    private static async Task<int> CreateStudentAsync(HttpClient c, string token, string first = "Sam")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", token, new
        {
            firstName = first,
            lastName = "Student",
            studentNumber = "001",
        }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    // Provisions a login for a student and returns their student token.
    private static async Task<string> StudentTokenAsync(
        HttpClient c, string teacherToken, int studentId, string email)
    {
        var acct = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/students/{studentId}/account",
            teacherToken, new { email, password = "pass1234" }));
        acct.EnsureSuccessStatusCode();

        var login = await c.PostAsJsonAsync("/api/v1/auth/login", new { email, password = "pass1234" });
        login.EnsureSuccessStatusCode();
        return (await login.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("token").GetString()!;
    }

    // A quiz with two questions; correct answers are the first choice of each.
    private static object SampleQuiz(string title = "Book Reading Exam") => new
    {
        title,
        description = "Chapter 1",
        category = "BookExam",
        bookReference = "Charlotte's Web",
        questions = new object[]
        {
            new
            {
                text = "Who is Wilbur?",
                choices = new object[]
                {
                    new { text = "A pig", isCorrect = true },
                    new { text = "A spider", isCorrect = false },
                },
            },
            new
            {
                text = "Who is Charlotte?",
                choices = new object[]
                {
                    new { text = "A spider", isCorrect = true },
                    new { text = "A rat", isCorrect = false },
                },
            },
        },
    };

    private static async Task<int> CreateQuizAsync(HttpClient c, string token, int classroomId, object? quiz = null)
    {
        var res = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/quizzes", token, quiz ?? SampleQuiz()));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    // --- tests -----------------------------------------------------------------

    [Fact]
    public async Task Create_Quiz_Fans_Out_One_Attempt_Per_Enrolled_Student()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);
        var s1 = await CreateStudentAsync(c, teacher, "A");
        var s2 = await CreateStudentAsync(c, teacher, "B");
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{s1}", teacher));
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{s2}", teacher));

        var quizId = await CreateQuizAsync(c, teacher, classId);

        var get = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/classrooms/{classId}/quizzes/{quizId}", teacher));
        get.EnsureSuccessStatusCode();
        var q = await get.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(2, q.GetProperty("questionCount").GetInt32());
        Assert.Equal(2, q.GetProperty("assignedCount").GetInt32());
        Assert.Equal(0, q.GetProperty("submittedCount").GetInt32());
    }

    [Fact]
    public async Task Non_Owner_Teacher_Gets_404()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var owner = await RegisterTeacherAsync(c, "owner@t.com");
        var intruder = await RegisterTeacherAsync(c, "intruder@t.com");
        var classId = await CreateClassroomAsync(c, owner);
        var quizId = await CreateQuizAsync(c, owner, classId);

        var list = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/classrooms/{classId}/quizzes", intruder));
        Assert.Equal(HttpStatusCode.NotFound, list.StatusCode);

        var analytics = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classId}/quizzes/{quizId}/analytics", intruder));
        Assert.Equal(HttpStatusCode.NotFound, analytics.StatusCode);
    }

    [Fact]
    public async Task Create_Rejects_Question_Without_A_Correct_Choice()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);

        var bad = new
        {
            title = "Bad",
            category = "General",
            questions = new object[]
            {
                new
                {
                    text = "No correct answer here",
                    choices = new object[]
                    {
                        new { text = "x", isCorrect = false },
                        new { text = "y", isCorrect = false },
                    },
                },
            },
        };

        var res = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/quizzes", teacher, bad));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task Student_Fetches_And_Submits_Quiz_Server_Recomputes_Score()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);
        var studentId = await CreateStudentAsync(c, teacher);
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{studentId}", teacher));
        var student = await StudentTokenAsync(c, teacher, studentId, "sam@s.com");
        await CreateQuizAsync(c, teacher, classId);

        // Student sees the quiz in their list.
        var list = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/quizzes", student));
        list.EnsureSuccessStatusCode();
        var quizzes = await list.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, quizzes.GetArrayLength());
        var attemptId = quizzes[0].GetProperty("attemptId").GetInt32();

        // Fetch the detail (choices include isCorrect for immediate feedback).
        var detail = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/student/quizzes/{attemptId}", student));
        detail.EnsureSuccessStatusCode();
        var dj = await detail.Content.ReadFromJsonAsync<JsonElement>();
        var questions = dj.GetProperty("questions");
        Assert.Equal(2, questions.GetArrayLength());

        // Answer Q1 correctly (its correct choice) and Q2 incorrectly.
        int q1Id = questions[0].GetProperty("questionId").GetInt32();
        int q1Correct = FindChoice(questions[0], correct: true);
        int q2Id = questions[1].GetProperty("questionId").GetInt32();
        int q2Wrong = FindChoice(questions[1], correct: false);

        var submit = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/student/quizzes/{attemptId}/submit", student,
            new { answers = new[] { new { questionId = q1Id, choiceId = q1Correct },
                                    new { questionId = q2Id, choiceId = q2Wrong } } }));
        submit.EnsureSuccessStatusCode();
        var result = await submit.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, result.GetProperty("score").GetInt32());
        Assert.Equal(2, result.GetProperty("totalQuestions").GetInt32());
    }

    [Fact]
    public async Task Double_Submit_Is_Rejected()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);
        var studentId = await CreateStudentAsync(c, teacher);
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{studentId}", teacher));
        var student = await StudentTokenAsync(c, teacher, studentId, "sam@s.com");
        await CreateQuizAsync(c, teacher, classId);

        var list = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/quizzes", student));
        var attemptId = (await list.Content.ReadFromJsonAsync<JsonElement>())[0]
            .GetProperty("attemptId").GetInt32();
        var detail = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/student/quizzes/{attemptId}", student));
        var questions = (await detail.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("questions");
        var answers = new List<object>();
        foreach (var q in questions.EnumerateArray())
            answers.Add(new { questionId = q.GetProperty("questionId").GetInt32(), choiceId = FindChoice(q, true) });

        var first = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/student/quizzes/{attemptId}/submit", student,
            new { answers }));
        first.EnsureSuccessStatusCode();

        var second = await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/student/quizzes/{attemptId}/submit", student,
            new { answers }));
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task Student_Cannot_Access_Another_Students_Attempt()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);
        var s1 = await CreateStudentAsync(c, teacher, "A");
        var s2 = await CreateStudentAsync(c, teacher, "B");
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{s1}", teacher));
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{s2}", teacher));
        var t1 = await StudentTokenAsync(c, teacher, s1, "a@s.com");
        var t2 = await StudentTokenAsync(c, teacher, s2, "b@s.com");
        await CreateQuizAsync(c, teacher, classId);

        // s1's attempt id.
        var list = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/quizzes", t1));
        var attemptId = (await list.Content.ReadFromJsonAsync<JsonElement>())[0]
            .GetProperty("attemptId").GetInt32();

        // s2 must not be able to read it.
        var foreign = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/student/quizzes/{attemptId}", t2));
        Assert.Equal(HttpStatusCode.NotFound, foreign.StatusCode);
    }

    [Fact]
    public async Task Analytics_Reflect_Submissions()
    {
        using var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var teacher = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, teacher);
        var studentId = await CreateStudentAsync(c, teacher);
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/classrooms/{classId}/students/{studentId}", teacher));
        var student = await StudentTokenAsync(c, teacher, studentId, "sam@s.com");
        var quizId = await CreateQuizAsync(c, teacher, classId);

        var list = await c.SendAsync(Req(HttpMethod.Get, "/api/v1/student/quizzes", student));
        var attemptId = (await list.Content.ReadFromJsonAsync<JsonElement>())[0]
            .GetProperty("attemptId").GetInt32();
        var detail = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/student/quizzes/{attemptId}", student));
        var questions = (await detail.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("questions");

        // Answer everything correctly → 100%.
        var answers = new List<object>();
        foreach (var q in questions.EnumerateArray())
            answers.Add(new { questionId = q.GetProperty("questionId").GetInt32(), choiceId = FindChoice(q, true) });
        await c.SendAsync(Req(HttpMethod.Post, $"/api/v1/student/quizzes/{attemptId}/submit", student, new { answers }));

        var analytics = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classId}/quizzes/{quizId}/analytics", teacher));
        analytics.EnsureSuccessStatusCode();
        var a = await analytics.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, a.GetProperty("submittedCount").GetInt32());
        Assert.Equal(100, a.GetProperty("averageScorePct").GetDouble());
        // Each question should show a 100% correct-rate.
        foreach (var qs in a.GetProperty("questions").EnumerateArray())
            Assert.Equal(100, qs.GetProperty("correctRatePct").GetDouble());
    }

    // Returns the choice id of the (in)correct choice for a student-detail question.
    private static int FindChoice(JsonElement question, bool correct)
    {
        foreach (var ch in question.GetProperty("choices").EnumerateArray())
            if (ch.GetProperty("isCorrect").GetBoolean() == correct)
                return ch.GetProperty("id").GetInt32();
        throw new InvalidOperationException("No matching choice.");
    }
}
