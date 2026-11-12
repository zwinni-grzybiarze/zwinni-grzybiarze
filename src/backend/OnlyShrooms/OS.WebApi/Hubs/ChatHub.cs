using Microsoft.AspNetCore.SignalR;
using OS.Interfaces.Services;
using OS.Model;
using OS.WebApi.Mapping;

namespace OS.WebApi.Hubs;

/// <summary>
/// Temporary identity: senderId/senderName come from the negotiate query string
/// until JWT/Google auth lands (#8 / #39). Do not treat this as security.
/// </summary>
public sealed class ChatHub(IChatService chatService) : Hub
{
    public async Task JoinRoom(string roomId)
    {
        var normalized = NormalizeRoomId(roomId);
        await Groups.AddToGroupAsync(Context.ConnectionId, normalized);
    }

    public async Task LeaveRoom(string roomId)
    {
        var normalized = NormalizeRoomId(roomId);
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, normalized);
    }

    public async Task SendMessage(string roomId, string body)
    {
        var http = Context.GetHttpContext()
            ?? throw new HubException("Missing HTTP context.");

        var senderId = http.Request.Query["senderId"].FirstOrDefault();
        var senderName = http.Request.Query["senderName"].FirstOrDefault();

        if (string.IsNullOrWhiteSpace(senderId) || string.IsNullOrWhiteSpace(senderName))
        {
            throw new HubException("senderId and senderName query parameters are required.");
        }

        try
        {
            var message = await chatService.SendAsync(roomId, senderId, senderName, body);
            var dto = ChatMessageDtoMapper.ToResponse(message);
            await Clients.Group(message.RoomId).SendAsync("ReceiveMessage", dto);
        }
        catch (ValidationFailedException ex)
        {
            throw new HubException(ex.Message);
        }
    }

    private static string NormalizeRoomId(string? roomId)
    {
        var value = roomId?.Trim();
        if (string.IsNullOrEmpty(value))
        {
            throw new HubException("RoomId is required.");
        }

        return value;
    }
}
