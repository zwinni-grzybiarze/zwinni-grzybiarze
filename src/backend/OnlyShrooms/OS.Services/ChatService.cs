using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class ChatService(IChatMessageRepository repository) : IChatService
{
    public Task<ChatMessage> SendAsync(
        string roomId,
        string senderId,
        string senderName,
        string body,
        CancellationToken cancellationToken = default)
    {
        var normalizedRoomId = NormalizeRoomId(roomId);
        var normalizedSenderId = NormalizeRequired(senderId, "SenderId");
        var normalizedSenderName = NormalizeRequired(senderName, "SenderName");
        var normalizedBody = NormalizeBody(body);

        var message = new ChatMessage
        {
            Id = Guid.NewGuid(),
            RoomId = normalizedRoomId,
            SenderId = normalizedSenderId,
            SenderName = normalizedSenderName,
            Body = normalizedBody,
            SentAt = DateTime.UtcNow,
        };

        return repository.AddAsync(message, cancellationToken);
    }

    public Task<IReadOnlyList<ChatMessage>> GetHistoryAsync(
        string roomId,
        DateTime? before = null,
        int limit = ChatRooms.DefaultHistoryLimit,
        CancellationToken cancellationToken = default)
    {
        var normalizedRoomId = NormalizeRoomId(roomId);
        var clampedLimit = Math.Clamp(limit, 1, ChatRooms.MaxHistoryLimit);
        return repository.GetHistoryAsync(normalizedRoomId, before, clampedLimit, cancellationToken);
    }

    private static string NormalizeRoomId(string? roomId)
    {
        var value = roomId?.Trim();
        if (string.IsNullOrEmpty(value))
        {
            throw new ValidationFailedException("RoomId is required.");
        }

        if (value.Length > 100)
        {
            throw new ValidationFailedException("RoomId is too long.");
        }

        return value;
    }

    private static string NormalizeRequired(string? value, string fieldName)
    {
        var trimmed = value?.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            throw new ValidationFailedException($"{fieldName} is required.");
        }

        return trimmed;
    }

    private static string NormalizeBody(string? body)
    {
        var trimmed = body?.Trim();
        if (string.IsNullOrEmpty(trimmed))
        {
            throw new ValidationFailedException("Body is required.");
        }

        if (trimmed.Length > ChatRooms.MaxBodyLength)
        {
            throw new ValidationFailedException($"Body must be at most {ChatRooms.MaxBodyLength} characters.");
        }

        return trimmed;
    }
}
