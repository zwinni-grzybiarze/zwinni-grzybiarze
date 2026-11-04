using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.Model;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;
[ApiController]
[Route("api/auth")]
public class GrzybiarzController(IGrzybiarzService service) : ControllerBase
{
    [Authorize]
    [HttpPost("me")]
    public async Task<ActionResult<Grzybiarz>> RegisterOrGetCurrentUser(CreateGrzybiarzRequest request,  CancellationToken cancellationToken)
    {
        var createdOrExisting = await service.GetOrCreateAsync(GrzybiarzDtoMapper.ToModel(request), cancellationToken);
        var response = GrzybiarzDtoMapper.ToResponse(createdOrExisting);

        return Ok(response);
    }
}
