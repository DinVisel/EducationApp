using Amazon.Rekognition;
using Amazon.Rekognition.Model;
using Microsoft.Extensions.Options;

namespace TeacherTracker.Api.Moderation;

/// <see cref="IImageModerator"/> backed by AWS Rekognition's
/// DetectModerationLabels. A label counts as a hit when its confidence clears the
/// configured threshold and its top-level category is in the block list.
public class RekognitionImageModerator : IImageModerator
{
    private readonly IAmazonRekognition _rekognition;
    private readonly ModerationOptions _options;
    private readonly ILogger<RekognitionImageModerator> _logger;

    public RekognitionImageModerator(
        IAmazonRekognition rekognition,
        IOptions<ModerationOptions> options,
        ILogger<RekognitionImageModerator> logger)
    {
        _rekognition = rekognition;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<ImageModerationResult> ScanAsync(Stream image, CancellationToken ct = default)
    {
        // Rekognition needs the raw bytes; buffer if the stream isn't already seekable.
        MemoryStream buffer;
        if (image is MemoryStream ms)
        {
            buffer = ms;
            buffer.Position = 0;
        }
        else
        {
            buffer = new MemoryStream();
            await image.CopyToAsync(buffer, ct);
            buffer.Position = 0;
        }

        var response = await _rekognition.DetectModerationLabelsAsync(
            new DetectModerationLabelsRequest
            {
                Image = new Image { Bytes = buffer },
                MinConfidence = _options.MinConfidence,
            }, ct);

        // A blocked label is one whose top-level category (ParentName when present,
        // else its own name) is in the configured block list. An empty block list
        // means any returned moderation label rejects the image.
        var blocked = new HashSet<string>(_options.BlockedLabels, StringComparer.OrdinalIgnoreCase);
        ModerationLabel? hit = null;
        foreach (var label in response.ModerationLabels)
        {
            var category = string.IsNullOrEmpty(label.ParentName) ? label.Name : label.ParentName;
            if (blocked.Count == 0 || blocked.Contains(category) || blocked.Contains(label.Name))
            {
                hit = label;
                break;
            }
        }

        if (hit is null)
            return ImageModerationResult.Clean;

        _logger.LogWarning(
            "Image moderation flagged content: {Label} ({Confidence:F1}%)",
            hit.Name, hit.Confidence);
        return new ImageModerationResult(true, hit.Name, hit.Confidence);
    }
}
