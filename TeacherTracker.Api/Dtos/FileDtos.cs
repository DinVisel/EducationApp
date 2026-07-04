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
