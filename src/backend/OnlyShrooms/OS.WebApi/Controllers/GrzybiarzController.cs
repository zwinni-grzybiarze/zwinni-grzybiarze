using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/grzybiarze")]
[Authorize]
public class GrzybiarzController(
    IGrzybiarzService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<GrzybiarzPublicResponse>>> List(
        CancellationToken cancellationToken)
    {
        var items = await service.ListAsync(cancellationToken);
        return Ok(items.Select(GrzybiarzDtoMapper.ToPublicResponse).ToList());
    }

    [HttpGet("me")]
    public async Task<ActionResult<GrzybiarzResponse>> GetMe(CancellationToken cancellationToken)
    {
        var email = User.FindFirst(ClaimTypes.Email)?.Value;
        if (string.IsNullOrWhiteSpace(email))
            return Unauthorized();

        var item = await service.GetByEmailAsync(email, cancellationToken);
        return item is null ? NotFound() : Ok(GrzybiarzDtoMapper.ToResponse(item));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<GrzybiarzPublicResponse>> GetById(
        int id,
        CancellationToken cancellationToken)
    {
        var item = await service.GetByIdAsync(id, cancellationToken);
        return item is null ? NotFound() : Ok(GrzybiarzDtoMapper.ToPublicResponse(item));
    }
}
