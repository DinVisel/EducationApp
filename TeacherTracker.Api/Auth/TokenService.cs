using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Auth;

public class TokenService
{
    private readonly JwtOptions _options;

    public TokenService(IOptions<JwtOptions> options)
    {
        _options = options.Value;
    }

    /// When the access token issued *now* would expire — surfaced to clients so
    /// they can refresh proactively rather than waiting for a 401.
    public DateTime AccessTokenExpiresAtUtc =>
        DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes);

    /// Mints a new refresh token: returns the raw value (handed to the client
    /// once, never stored) alongside the row to persist (stores only the hash).
    public (string RawToken, RefreshToken Entity) CreateRefreshToken(int userId)
    {
        var raw = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        var entity = new RefreshToken
        {
            UserId = userId,
            TokenHash = HashToken(raw),
            ExpiresAtUtc = DateTime.UtcNow.AddDays(_options.RefreshTokenDays),
        };
        return (raw, entity);
    }

    /// SHA-256 hex of a raw token. Used for both storing and looking up refresh
    /// tokens (and reused for password-reset tokens).
    public static string HashToken(string rawToken) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(rawToken)));

    /// Issues a signed JWT whose subject is the user's id. When the user has a
    /// teacher or student profile, a `teacherId`/`studentId` claim is included so
    /// role-scoped controllers can resolve it directly.
    public string CreateToken(User user, Teacher? teacher = null, Student? student = null)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            // Access-card students have no email; omit the claim rather than emit
            // an empty one (the Claim ctor rejects a null value).
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("role", user.Role.ToString()),
            new(ClaimTypes.Role, user.Role.ToString()),
        };

        if (teacher is not null)
        {
            claims.Add(new Claim("teacherId", teacher.Id.ToString()));
            claims.Add(new Claim("name",
                $"{teacher.FirstName} {teacher.LastName}".Trim()));
        }

        if (student is not null)
        {
            claims.Add(new Claim("studentId", student.Id.ToString()));
            claims.Add(new Claim("name",
                $"{student.FirstName} {student.LastName}".Trim()));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Key));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_options.ExpiryMinutes),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
