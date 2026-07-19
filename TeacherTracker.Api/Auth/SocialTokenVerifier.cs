using System.IdentityModel.Tokens.Jwt;
using Google.Apis.Auth;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Protocols;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using TeacherTracker.Api.Dtos;

namespace TeacherTracker.Api.Auth;

/// A verified social identity: the provider's stable subject id plus whatever
/// profile fields we could trust. Email is only set when the provider marked it
/// verified.
public record SocialIdentity(
    string Subject,
    string? Email,
    string? FirstName,
    string? LastName);

/// Validates Apple / Google ID tokens against the provider's public keys and
/// our configured audiences. A returned <see cref="SocialIdentity"/> means the
/// token's signature, issuer, audience, and expiry all checked out; anything
/// wrong throws.
public class SocialTokenVerifier
{
    private const string AppleMetadata =
        "https://appleid.apple.com/.well-known/openid-configuration";
    private const string AppleIssuer = "https://appleid.apple.com";

    private readonly SocialAuthOptions _options;
    // Caches Apple's signing keys (JWKS) and refreshes them on rotation.
    private readonly ConfigurationManager<OpenIdConnectConfiguration> _appleConfig;

    public SocialTokenVerifier(IOptions<SocialAuthOptions> options)
    {
        _options = options.Value;
        _appleConfig = new ConfigurationManager<OpenIdConnectConfiguration>(
            AppleMetadata, new OpenIdConnectConfigurationRetriever());
    }

    /// Verifies a Google-issued ID token (audience = one of our Google client IDs)
    /// and returns the identity. Throws <see cref="InvalidJwtException"/> or
    /// similar on any failure.
    public async Task<SocialIdentity> VerifyGoogleAsync(string idToken)
    {
        var payload = await GoogleJsonWebSignature.ValidateAsync(idToken,
            new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = _options.Google.ClientIds,
            });

        return new SocialIdentity(
            payload.Subject,
            payload.EmailVerified ? payload.Email : null,
            payload.GivenName,
            payload.FamilyName);
    }

    /// Verifies an Apple-issued ID token. Apple omits the user's name from the
    /// token (it's only returned to the client on first authorization), so the
    /// caller supplies [fallbackFirst]/[fallbackLast] from the client for account
    /// creation. When [expectedNonce] is set it must match the token's nonce.
    public async Task<SocialIdentity> VerifyAppleAsync(
        string idToken, string? expectedNonce, string? fallbackFirst, string? fallbackLast)
    {
        var config = await _appleConfig.GetConfigurationAsync(CancellationToken.None);

        var parameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = AppleIssuer,
            ValidateAudience = true,
            ValidAudiences = _options.Apple.ClientIds,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys = config.SigningKeys,
        };

        var principal = new JwtSecurityTokenHandler()
            .ValidateToken(idToken, parameters, out _);

        // Bind the token to the client's sign-in attempt when a nonce was used.
        if (!string.IsNullOrEmpty(expectedNonce))
        {
            var nonce = principal.FindFirst("nonce")?.Value;
            if (nonce != expectedNonce)
                throw new SecurityTokenValidationException("Nonce mismatch.");
        }

        var subject = principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? throw new SecurityTokenValidationException("Token has no subject.");

        var email = principal.FindFirst(JwtRegisteredClaimNames.Email)?.Value;
        var emailVerified =
            principal.FindFirst("email_verified")?.Value is "true" or "True";

        return new SocialIdentity(
            subject,
            emailVerified ? email : null,
            fallbackFirst,
            fallbackLast);
    }
}
