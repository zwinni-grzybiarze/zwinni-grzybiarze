using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/zadania")]
public class ZadanieController(IZadanieService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ZadanieResponse>>> GetAll(CancellationToken cancellationToken)
    {
        var items = await service.GetAllAsync(cancellationToken);
        return Ok(items.Select(ZadanieDtoMapper.ToResponse).ToArray());
    }

    [HttpGet("{id:int}", Name = "GetZadanie")]
    public async Task<ActionResult<ZadanieResponse>> GetById(int id, CancellationToken cancellationToken)
    {
        var item = await service.GetByIdAsync(id, cancellationToken);
        return item is null ? NotFound() : Ok(ZadanieDtoMapper.ToResponse(item));
    }

    [HttpPost]
    public async Task<ActionResult<ZadanieResponse>> Create(CreateZadanieRequest request, CancellationToken cancellationToken)
    {
        var created = await service.CreateAsync(ZadanieDtoMapper.ToModel(request), cancellationToken);
        var response = ZadanieDtoMapper.ToResponse(created);

        return CreatedAtRoute("GetZadanie", new { id = response.Id }, response);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ZadanieResponse>> Update(int id, UpdateZadanieRequest request, CancellationToken cancellationToken)
    {
        var updated = await service.UpdateAsync(id, ZadanieDtoMapper.ToModel(request), cancellationToken);
        return updated is null ? NotFound() : Ok(ZadanieDtoMapper.ToResponse(updated));
    }
}
