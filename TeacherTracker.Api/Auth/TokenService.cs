using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
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

    /// Issues a signed JWT whose subject is the user's id. When the user has a
    /// teacher profile, a `teacherId` claim is included so teacher-scoped
    /// controllers can resolve it directly.
    public string CreateToken(User user, Teacher? teacher = null)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email),
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
