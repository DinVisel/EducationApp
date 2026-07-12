namespace TeacherTracker.Api.Moderation;

/// The outcome of scanning an image for inappropriate content.
public record ImageModerationResult(bool IsFlagged, string? TopLabel, float TopConfidence)
{
    public static readonly ImageModerationResult Clean = new(false, null, 0f);
}

/// Scans image bytes for inappropriate content (nudity, violence, etc.) before an
/// upload is promoted out of quarantine. Only image content types are scanned;
/// callers guard non-images.
public interface IImageModerator
{
    Task<ImageModerationResult> ScanAsync(Stream image, CancellationToken ct = default);
}
