namespace TeacherTracker.Api.Auth;

/// Bound from the "SocialAuth" configuration section. Holds the accepted client
/// IDs (token audiences) for each provider. Populate these per platform from the
/// provider consoles (real values via env/user-secrets, like the JWT key).
public class SocialAuthOptions
{
    public const string SectionName = "SocialAuth";

    public ProviderOptions Google { get; set; } = new();
    public ProviderOptions Apple { get; set; } = new();

    public class ProviderOptions
    {
        // Every client ID whose tokens we accept. Google: the iOS, Android, and
        // Web OAuth client IDs (google_sign_in mints the ID token for the
        // serverClientId / Web client). Apple: the app's bundle ID and any
        // Service ID used for the Android web flow.
        public string[] ClientIds { get; set; } = [];
    }
}
