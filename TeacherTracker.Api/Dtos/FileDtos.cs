using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

/// A stored file's public metadata (the R2 key is never exposed).
public record FileObjectDto(
    int Id,
    string FileName,
    string ContentType,
    long Size,
    DateTime CreatedAt);

/// A time-limited direct download URL for a file.
public record FileUrlDto(string Url);

/// Request a presigned PUT URL to upload a file directly to R2.
public record PresignUploadDto(
    [Required, MaxLength(260)] string FileName,
    [MaxLength(120)] string? ContentType);

/// The presigned PUT URL plus the R2 key the client must confirm after uploading.
public record PresignUploadResponseDto(string UploadUrl, string Key);

/// Confirm a direct upload landed, registering its metadata. `Key` must be one
/// this caller was issued by `presign`.
public record ConfirmUploadDto(
    [Required] string Key,
    [Required, MaxLength(260)] string FileName,
    [MaxLength(120)] string? ContentType);
