using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

public record TrackingNoteDto(
    int Id,
    string Category,
    string Content,
    DateTime CreatedAt,
    int StudentId);

public record CreateTrackingNoteDto(
    [Required, MaxLength(50)] string Category,
    [Required, MaxLength(2000)] string Content);

public record UpdateTrackingNoteDto(
    [Required, MaxLength(50)] string Category,
    [Required, MaxLength(2000)] string Content);
