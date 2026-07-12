namespace TeacherTracker.Api.Moderation;

/// A no-op <see cref="IImageModerator"/> that passes every image. Registered when
/// image moderation is disabled (no AWS Rekognition credentials configured), and
/// used by tests that don't exercise the moderation branch.
public class NullImageModerator : IImageModerator
{
    public Task<ImageModerationResult> ScanAsync(Stream image, CancellationToken ct = default) =>
        Task.FromResult(ImageModerationResult.Clean);
}
