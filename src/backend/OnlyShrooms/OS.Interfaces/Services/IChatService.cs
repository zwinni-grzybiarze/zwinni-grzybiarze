using OS.Model;

namespace OS.Interfaces.Services;

public interface IChatService
{
    Task<ChatMessage> SendAsync(
        string roomId,
        string senderId,
        string senderName,
        string body,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ChatMessage>> GetHistoryAsync(
        string roomId,
        DateTime? before = null,
        int limit = ChatRooms.DefaultHistoryLimit,
        CancellationToken cancellationToken = default);
}
