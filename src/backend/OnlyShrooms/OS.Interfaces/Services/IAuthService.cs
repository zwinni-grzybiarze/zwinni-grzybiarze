using System.Security.Claims;

namespace OS.Interfaces.Services;

public interface IAuthService
{
    string CreateJwt(ClaimsPrincipal claim);
}
