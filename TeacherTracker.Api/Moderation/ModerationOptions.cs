namespace TeacherTracker.Api.Moderation;

/// Content-moderation settings. Image moderation uses AWS Rekognition, which needs
/// a *real* AWS account + region (the R2 credentials/region alias won't authorize
/// it unless they belong to the same AWS account). Real keys belong in
/// `dotnet user-secrets` / environment variables — never in appsettings.json.
public class ModerationOptions
{
    public const string SectionName = "Moderation";

    // --- Image moderation (AWS Rekognition) ---

    /// When false, images are never scanned (clean-passthrough). Lets tests and
    /// trusted/offline deployments run without AWS Rekognition credentials.
    public bool ImageModerationEnabled { get; set; } = false;

    public string AwsAccessKey { get; set; } = string.Empty;
    public string AwsSecretKey { get; set; } = string.Empty;

    /// A real AWS region for Rekognition, e.g. "us-east-1".
    public string AwsRegion { get; set; } = "us-east-1";

    /// Minimum confidence (0–100) for a moderation label to count as a hit.
    public float MinConfidence { get; set; } = 80f;

    /// Top-level Rekognition moderation categories that cause rejection. Matched
    /// against the label's top-level parent so a single entry covers its children
    /// (e.g. "Explicit Nudity" covers "Graphic Male Nudity"). Empty = block all.
    public List<string> BlockedLabels { get; set; } = new()
    {
        "Explicit Nudity",
        "Violence",
        "Visually Disturbing",
        "Hate Symbols",
        "Drugs",
    };

    // --- Text moderation (profanity / sensitive keywords) ---

    /// When false, text is never filtered. On by default.
    public bool TextModerationEnabled { get; set; } = true;

    /// Extra blocked terms merged with the bundled default list (TR + EN).
    public List<string> BlockedTerms { get; set; } = new();
}
