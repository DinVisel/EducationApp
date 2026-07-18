using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace TeacherTracker.Api.Tests;

/// End-to-end coverage for attendance: bulk marking, re-marking (upsert, no
/// duplicates), ownership scoping, history, and summary percentages.
public class AttendanceTests
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

    private static async Task<int> CreateClassroomAsync(HttpClient c, string token, string name = "Class A")
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/classrooms", token, new { name }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    private static async Task<int> CreateStudentAsync(HttpClient c, string token, string first)
    {
        var res = await c.SendAsync(Req(HttpMethod.Post, "/api/v1/students", token, new
        {
            firstName = first,
            lastName = "Student",
            studentNumber = first,
        }));
        res.EnsureSuccessStatusCode();
        return (await res.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
    }

    private static async Task EnrollAsync(HttpClient c, string token, int classroomId, int studentId)
    {
        var res = await c.SendAsync(Req(HttpMethod.Post,
            $"/api/v1/classrooms/{classroomId}/students/{studentId}", token));
        res.EnsureSuccessStatusCode();
    }

    private static async Task<(HttpClient c, string token, int classId, int s1, int s2)> SetupAsync()
    {
        var factory = new TestApiFactory();
        var c = factory.CreateApiClient();
        var token = await RegisterTeacherAsync(c, "t@t.com");
        var classId = await CreateClassroomAsync(c, token);
        var s1 = await CreateStudentAsync(c, token, "Amy");
        var s2 = await CreateStudentAsync(c, token, "Bob");
        await EnrollAsync(c, token, classId, s1);
        await EnrollAsync(c, token, classId, s2);
        return (c, token, classId, s1, s2);
    }

    [Fact]
    public async Task Mark_Then_GetDay_Reflects_Statuses()
    {
        var (c, token, classId, s1, s2) = await SetupAsync();

        var mark = await c.SendAsync(Req(HttpMethod.Put,
            $"/api/v1/classrooms/{classId}/attendance", token, new
            {
                date = "2026-07-18",
                entries = new[]
                {
                    new { studentId = s1, status = "Present", note = (string?)null },
                    new { studentId = s2, status = "Absent", note = "Sick" },
                },
            }));
        Assert.Equal(HttpStatusCode.NoContent, mark.StatusCode);

        var day = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classId}/attendance?date=2026-07-18", token));
        day.EnsureSuccessStatusCode();
        var json = await day.Content.ReadFromJsonAsync<JsonElement>();
        var students = json.GetProperty("students").EnumerateArray().ToList();
        Assert.Equal(2, students.Count);
        var amy = students.First(s => s.GetProperty("studentId").GetInt32() == s1);
        var bob = students.First(s => s.GetProperty("studentId").GetInt32() == s2);
        Assert.Equal("Present", amy.GetProperty("status").GetString());
        Assert.Equal("Absent", bob.GetProperty("status").GetString());
        Assert.Equal("Sick", bob.GetProperty("note").GetString());
    }

    [Fact]
    public async Task Remarking_Updates_In_Place_Without_Duplicates()
    {
        var (c, token, classId, s1, _) = await SetupAsync();

        async Task Mark(string status) => (await c.SendAsync(Req(HttpMethod.Put,
            $"/api/v1/classrooms/{classId}/attendance", token, new
            {
                date = "2026-07-18",
                entries = new[] { new { studentId = s1, status, note = (string?)null } },
            }))).EnsureSuccessStatusCode();

        await Mark("Absent");
        await Mark("Present");

        // History should hold a single, updated record.
        var hist = await c.SendAsync(Req(HttpMethod.Get,
            $"/api/v1/classrooms/{classId}/attendance/students/{s1}/history", token));
        hist.EnsureSuccessStatusCode();
        var records = (await hist.Content.ReadFromJsonAsync<JsonElement>()).EnumerateArray().ToList();
        Assert.Single(records);
        Assert.Equal("Present", records[0].GetProperty("status").GetString());
    }

    [Fact]
    public async Task Summary_Computes_Attendance_Percent()
    {
        var (c, token, classId, s1, _) = await SetupAsync();

        // Two present-ish days (Present + Late count) and one absent = 2/3 ≈ 66.7%.
        await c.SendAsync(Req(HttpMethod.Put, $"/api/v1/classrooms/{classId}/attendance", token,
            new { date = "2026-07-16", entries = new[] { new { studentId = s1, status = "Present", note = (string?)null } } }));
        await c.SendAsync(Req(HttpMethod.Put, $"/api/v1/classrooms/{classId}/attendance", token,
            new { date = "2026-07-17", entries = new[] { new { studentId = s1, status = "Late", note = (string?)null } } }));
        await c.SendAsync(Req(HttpMethod.Put, $"/api/v1/classrooms/{classId}/attendance", token,
            new { date = "2026-07-18", entries = new[] { new { studentId = s1, status = "Absent", note = (string?)null } } }));

        var res = await c.SendAsync(Req(HttpMethod.Get, $"/api/v1/classrooms/{classId}/attendance/summary", token));
        res.EnsureSuccessStatusCode();
        var summaries = (await res.Content.ReadFromJsonAsync<JsonElement>()).EnumerateArray().ToList();
        var amy = summaries.First(s => s.GetProperty("studentId").GetInt32() == s1);
        Assert.Equal(1, amy.GetProperty("present").GetInt32());
        Assert.Equal(1, amy.GetProperty("late").GetInt32());
        Assert.Equal(1, amy.GetProperty("absent").GetInt32());
        Assert.Equal(3, amy.GetProperty("totalDays").GetInt32());
        Assert.Equal(66.7, amy.GetProperty("attendancePercent").GetDouble());
    }

    [Fact]
    public async Task Cannot_Mark_Another_Teachers_Class()
    {
        var (c, _, classId, s1, _) = await SetupAsync();
        var otherToken = await RegisterTeacherAsync(c, "other@t.com");

        var res = await c.SendAsync(Req(HttpMethod.Put,
            $"/api/v1/classrooms/{classId}/attendance", otherToken, new
            {
                date = "2026-07-18",
                entries = new[] { new { studentId = s1, status = "Present", note = (string?)null } },
            }));
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    [Fact]
    public async Task Cannot_Mark_Unenrolled_Student()
    {
        var (c, token, classId, _, _) = await SetupAsync();
        var outsider = await CreateStudentAsync(c, token, "Zed"); // not enrolled

        var res = await c.SendAsync(Req(HttpMethod.Put,
            $"/api/v1/classrooms/{classId}/attendance", token, new
            {
                date = "2026-07-18",
                entries = new[] { new { studentId = outsider, status = "Present", note = (string?)null } },
            }));
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }
}
