namespace TeacherTracker.Api.Auth;

/// Bound from the "Jwt" configuration section.
public class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public string Key { get; set; } = string.Empty;

    // Short-lived access token. Clients refresh it with their refresh token.
    public int ExpiryMinutes { get; set; } = 30;

    // Long-lived refresh token; rotated on every use.
    public int RefreshTokenDays { get; set; } = 30;
}
