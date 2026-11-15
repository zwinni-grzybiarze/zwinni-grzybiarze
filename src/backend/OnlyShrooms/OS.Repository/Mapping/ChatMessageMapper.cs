using OS.Entities;
using OS.Model;
using Riok.Mapperly.Abstractions;

namespace OS.Repository.Mapping;

[Mapper]
internal static partial class ChatMessageMapper
{
    public static partial ChatMessage ToModel(ChatMessageEntity entity);

    public static partial ChatMessageEntity ToEntity(ChatMessage model);
}
