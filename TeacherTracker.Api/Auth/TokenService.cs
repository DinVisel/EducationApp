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

    /// Issues a signed JWT whose subject is the teacher's id.
    public string CreateToken(Teacher teacher)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, teacher.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, teacher.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("name", $"{teacher.FirstName} {teacher.LastName}".Trim()),
        };

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
