using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/grzybobrania")]
public class GrzybobranieController(IGrzybobranieService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<GrzybobranieResponse>>> GetAll(CancellationToken cancellationToken)
    {
        var items = await service.GetAllAsync(cancellationToken);
        return Ok(items.Select(GrzybobranieDtoMapper.ToResponse).ToArray());
    }

    [HttpGet("{id:int}", Name = "GetGrzybobranie")]
    public async Task<ActionResult<GrzybobranieResponse>> GetById(int id, CancellationToken cancellationToken)
    {
        var item = await service.GetByIdAsync(id, cancellationToken);
        return item is null ? NotFound() : Ok(GrzybobranieDtoMapper.ToResponse(item));
    }

    [HttpPost]
    public async Task<ActionResult<GrzybobranieResponse>> Create(CreateGrzybobranieRequest request, CancellationToken cancellationToken)
    {
        var created = await service.CreateAsync(GrzybobranieDtoMapper.ToModel(request), cancellationToken);
        var response = GrzybobranieDtoMapper.ToResponse(created);

        return CreatedAtRoute("GetGrzybobranie", new { id = response.Id }, response);
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<GrzybobranieResponse>> Update(int id, UpdateGrzybobranieRequest request, CancellationToken cancellationToken)
    {
        var updated = await service.UpdateAsync(id, GrzybobranieDtoMapper.ToModel(request), cancellationToken);
        return updated is null ? NotFound() : Ok(GrzybobranieDtoMapper.ToResponse(updated));
    }
}
