using OS.Interfaces.Repositories;
using OS.Model;

namespace OS.Services.Tests;

internal sealed class FakeChatMessageRepository : IChatMessageRepository
{
    private readonly List<ChatMessage> _items = [];

    public Task<ChatMessage> AddAsync(ChatMessage message, CancellationToken cancellationToken = default)
    {
        _items.Add(message);
        return Task.FromResult(message);
    }

    public Task<IReadOnlyList<ChatMessage>> GetHistoryAsync(
        string roomId,
        DateTime? before = null,
        int limit = ChatRooms.DefaultHistoryLimit,
        CancellationToken cancellationToken = default)
    {
        IEnumerable<ChatMessage> query = _items.Where(m => m.RoomId == roomId);
        if (before.HasValue)
        {
            query = query.Where(m => m.SentAt < before.Value);
        }

        var page = query
            .OrderByDescending(m => m.SentAt)
            .ThenByDescending(m => m.Id)
            .Take(limit)
            .Reverse()
            .ToList();

        return Task.FromResult<IReadOnlyList<ChatMessage>>(page);
    }
}
