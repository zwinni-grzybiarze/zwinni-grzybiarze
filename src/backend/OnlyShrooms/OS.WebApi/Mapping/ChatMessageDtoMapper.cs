using OS.Model;
using OS.WebApiDto;
using Riok.Mapperly.Abstractions;

namespace OS.WebApi.Mapping;

[Mapper]
internal static partial class ChatMessageDtoMapper
{
    [MapProperty(nameof(ChatMessage.Id), nameof(ChatMessageResponse.Id))]
    public static partial ChatMessageResponse ToResponse(ChatMessage message);
}
