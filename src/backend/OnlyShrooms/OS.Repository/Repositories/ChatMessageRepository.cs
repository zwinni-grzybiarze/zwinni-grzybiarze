using Microsoft.EntityFrameworkCore;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Repository.Mapping;

namespace OS.Repository.Repositories;

internal sealed class ChatMessageRepository(OsDbContext context) : IChatMessageRepository
{
    public async Task<ChatMessage> AddAsync(ChatMessage message, CancellationToken cancellationToken = default)
    {
        var entity = ChatMessageMapper.ToEntity(message);
        context.ChatMessages.Add(entity);
        await context.SaveChangesAsync(cancellationToken);
        return ChatMessageMapper.ToModel(entity);
    }

    public async Task<IReadOnlyList<ChatMessage>> GetHistoryAsync(
        string roomId,
        DateTime? before = null,
        int limit = ChatRooms.DefaultHistoryLimit,
        CancellationToken cancellationToken = default)
    {
        var query = context.ChatMessages
            .AsNoTracking()
            .Where(m => m.RoomId == roomId);

        if (before.HasValue)
        {
            var cursor = before.Value.Kind == DateTimeKind.Unspecified
                ? DateTime.SpecifyKind(before.Value, DateTimeKind.Utc)
                : before.Value.ToUniversalTime();
            query = query.Where(m => m.SentAt < cursor);
        }

        var entities = await query
            .OrderByDescending(m => m.SentAt)
            .ThenByDescending(m => m.Id)
            .Take(limit)
            .ToListAsync(cancellationToken);

        entities.Reverse();
        return entities.Select(ChatMessageMapper.ToModel).ToList();
    }
}
