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
