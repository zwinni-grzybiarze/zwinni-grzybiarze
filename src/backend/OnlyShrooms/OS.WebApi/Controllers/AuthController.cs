using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.WebApi.Controllers;
[ApiController]
[Route("api/auth")]
public class AuthController(IGrzybiarzService service) : ControllerBase
{
    [Authorize]
    [HttpPost("me")]
    public async Task<ActionResult<Grzybiarz>> RegisterOrGetCurrentUser(CancellationToken cancellationToken)
    {
        var subject = User.FindFirst("sub")?.Value;
        if (string.IsNullOrWhiteSpace(subject))
        {
            return Unauthorized();
        }

        var user = new Grzybiarz
        {
            KeycloakId = subject,
            Email = User.FindFirst("email")?.Value,
            Imie = User.FindFirst("given_name")?.Value ?? string.Empty,
            Nazwisko = User.FindFirst("family_name")?.Value ?? string.Empty,
        };

        var saved = await service.GetOrCreateAsync(user, cancellationToken);
        return Ok(saved);
    }
}
