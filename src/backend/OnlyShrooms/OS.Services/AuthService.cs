using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using OS.Interfaces.Services;
using Microsoft.IdentityModel.Tokens;

namespace OS.Services;

public class AuthService(SymmetricSecurityKey jwtSigningKey) : IAuthService
{
    public string CreateJwt(ClaimsPrincipal claim)
    {
        var key = jwtSigningKey;
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: "OnlyShrooms.Api",
            audience: "OnlyShrooms.Api",
            claims: claim.Claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
