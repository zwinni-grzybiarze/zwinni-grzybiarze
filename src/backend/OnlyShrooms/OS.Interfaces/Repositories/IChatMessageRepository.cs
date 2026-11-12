using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IChatMessageRepository
{
    Task<ChatMessage> AddAsync(ChatMessage message, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns up to <paramref name="limit"/> most recent messages in a room,
    /// optionally older than <paramref name="before"/>, ordered ascending by SentAt.
    /// </summary>
    Task<IReadOnlyList<ChatMessage>> GetHistoryAsync(
        string roomId,
        DateTime? before = null,
        int limit = ChatRooms.DefaultHistoryLimit,
        CancellationToken cancellationToken = default);
}
