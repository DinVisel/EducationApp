namespace TeacherTracker.Api.Dtos;

/// Platform-wide totals shown as KPI cards on the admin dashboard. Counts respect
/// the soft-delete query filters on Users/Posts (deleted rows are excluded).
public record AdminStatsDto(
    int TotalUsers,
    int TotalTeachers,
    int TotalStudents,
    int TotalAdmins,
    int TotalClassrooms,
    int TotalPosts,
    int TotalQuizzes,
    int OpenReports,
    int NewUsersLast7Days,
    int PostsLast7Days);

/// One day's count, for the signups-per-day and posts-per-day charts. Days with
/// no activity are included with a zero count so the series is continuous.
public record TimeSeriesPointDto(DateOnly Date, int Count);

/// The full admin overview payload: headline KPIs plus 30-day daily time series
/// for new signups and new posts.
public record AdminOverviewDto(
    AdminStatsDto Stats,
    IReadOnlyList<TimeSeriesPointDto> Signups,
    IReadOnlyList<TimeSeriesPointDto> Posts);

/// One slice of a teacher distribution: a category label and how many teachers
/// fall into it. Used by every chart on the teacher-analytics dashboard.
public record CategoryCountDto(string Label, int Count);

/// Teacher demographic analytics, computed with provider-side GROUP BY
/// aggregations. Each distribution is ordered by descending count. `ByDistrict`
/// is scoped to a single city (see the endpoint's `city` query param) since
/// districts are only meaningful within a city.
public record TeacherStatsDto(
    int TotalTeachers,
    // Teachers who have filled in at least their city (proxy for "onboarded").
    int WithLocation,
    IReadOnlyList<CategoryCountDto> ByCity,
    IReadOnlyList<CategoryCountDto> BySchoolType,
    IReadOnlyList<CategoryCountDto> ByEducationLevel,
    // Districts for the requested city, or empty when no city was requested.
    string? DistrictCity,
    IReadOnlyList<CategoryCountDto> ByDistrict);
