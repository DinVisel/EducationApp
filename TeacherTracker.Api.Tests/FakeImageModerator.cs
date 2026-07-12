using TeacherTracker.Api.Moderation;

namespace TeacherTracker.Api.Tests;

/// A test <see cref="IImageModerator"/> whose verdict is switchable per test.
/// Default: clean (passes every image).
public class FakeImageModerator : IImageModerator
{
    public bool Flagged { get; set; }

    public Task<ImageModerationResult> ScanAsync(Stream image, CancellationToken ct = default) =>
        Task.FromResult(Flagged
            ? new ImageModerationResult(true, "Explicit Nudity", 99f)
            : ImageModerationResult.Clean);
}
