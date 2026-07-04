using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

/// A file attached to an assignment. `FileId` is the id used with
/// `GET /api/files/{id}` to obtain a presigned download URL.
public record AssignmentAttachmentDto(
    int FileId,
    string FileName,
    string ContentType,
    long Size);

/// Summary of an assignment published to a class, with fan-out progress.
public record AssignmentDto(
    int Id,
    string Title,
    string? Description,
    DateOnly? DueDate,
    DateTime CreatedAt,
    int ClassroomId,
    int StudentCount,
    int CompletedCount,
    IReadOnlyList<AssignmentAttachmentDto> Attachments);

public record CreateAssignmentDto(
    [Required, MaxLength(200)] string Title,
    [MaxLength(2000)] string? Description,
    DateOnly? DueDate,
    // Ids of already-uploaded files (POST /api/files) to attach.
    IReadOnlyList<int>? FileIds);
