using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// A user's reason for reporting a post or comment.
public record CreateReportDto(
    [Required, MaxLength(500)] string Reason);

/// A report as an admin reviews it, with a snapshot of the reported content.
/// `TargetType` is "Post" or "Comment"; `TargetText`/`TargetAuthorName` are null
/// when the content has already been removed.
public record ReportDto(
    int Id,
    string Reason,
    DateTime CreatedAt,
    string ReporterName,
    string TargetType,
    int? TargetId,
    string? TargetText,
    string? TargetAuthorName,
    bool IsResolved,
    ReportResolution? Resolution);
