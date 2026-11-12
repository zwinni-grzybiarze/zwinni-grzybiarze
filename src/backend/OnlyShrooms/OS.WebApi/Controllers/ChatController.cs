using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.Model;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/chat")]
public class ChatController(IChatService service) : ControllerBase
{
    [HttpGet("rooms/{roomId}/messages")]
    public async Task<ActionResult<IEnumerable<ChatMessageResponse>>> GetHistory(
        string roomId,
        [FromQuery] DateTime? before,
        [FromQuery] int? limit,
        CancellationToken cancellationToken)
    {
        var items = await service.GetHistoryAsync(
            roomId,
            before,
            limit ?? ChatRooms.DefaultHistoryLimit,
            cancellationToken);

        return Ok(items.Select(ChatMessageDtoMapper.ToResponse).ToArray());
    }
}
