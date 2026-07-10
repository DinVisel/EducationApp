namespace TeacherTracker.Api.Models;

/// How an admin resolved a <see cref="Report"/>. Stored as text (see AppDbContext).
public enum ReportResolution
{
    Dismissed,
    ContentRemoved,
}
