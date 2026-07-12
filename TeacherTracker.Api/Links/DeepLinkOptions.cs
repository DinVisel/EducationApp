namespace TeacherTracker.Api.Links;

/// Settings for shareable post links and native deep linking. Values are
/// deployment-specific (real domain, Apple Team ID, Android signing fingerprint,
/// store URLs) — fill them in via environment variables / user-secrets. The
/// committed appsettings.json ships placeholders.
public class DeepLinkOptions
{
    public const string SectionName = "DeepLink";

    /// Public HTTPS base a shared post URL is built from, e.g.
    /// "https://app.example.com". Universal/App Links are verified against this host.
    public string PublicWebBaseUrl { get; set; } = string.Empty;

    /// Optional custom URL scheme the fallback page uses to try opening the app
    /// when it's installed but the OS didn't intercept the link, e.g. "teachertracker".
    public string AppScheme { get; set; } = "teachertracker";

    // --- iOS (Universal Links) ---
    public string IosTeamId { get; set; } = string.Empty;
    public string IosBundleId { get; set; } = string.Empty;
    public string AppStoreUrl { get; set; } = string.Empty;

    // --- Android (App Links) ---
    public string AndroidPackageName { get; set; } = string.Empty;

    /// SHA-256 signing-certificate fingerprints of the release/debug keystores.
    public List<string> AndroidSha256CertFingerprints { get; set; } = new();
    public string PlayStoreUrl { get; set; } = string.Empty;
}
