using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/grzybiarze")]
public class GrzybiarzController(
    IGrzybiarzService service) : ControllerBase
{
    [HttpGet("{email}")]
    public async Task<ActionResult<GrzybiarzResponse>> GetByEmail(string email,
        CancellationToken cancellationToken)
    {
        var item = await service.GetByEmailAsync(email, cancellationToken);
        return item is null ? NotFound() : Ok(GrzybiarzDtoMapper.ToResponse(item));
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<GrzybiarzResponse>> GetMe(CancellationToken cancellationToken)
    {
        var email = User.FindFirst(ClaimTypes.Email)?.Value;
        if (string.IsNullOrWhiteSpace(email))
            return Unauthorized();

        var item = await service.GetByEmailAsync(email, cancellationToken);
        return item is null ? NotFound() : Ok(GrzybiarzDtoMapper.ToResponse(item));
    }
}
