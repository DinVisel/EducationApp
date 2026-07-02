namespace TeacherTracker.Api.Auth;

/// Bound from the "Jwt" configuration section.
public class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;
    public int ExpiryMinutes { get; set; } = 60 * 24 * 7; // 7 days
}
