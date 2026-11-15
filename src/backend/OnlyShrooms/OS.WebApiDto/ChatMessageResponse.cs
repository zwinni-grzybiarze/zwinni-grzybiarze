using System.Text.Json.Serialization;

namespace OS.WebApiDto;

public class ChatMessageResponse
{
    [JsonPropertyName("chatMessageId")]
    public Guid Id { get; set; }

    public string RoomId { get; set; } = string.Empty;

    public string SenderId { get; set; } = string.Empty;

    public string SenderName { get; set; } = string.Empty;

    public string Body { get; set; } = string.Empty;

    public DateTime SentAt { get; set; }
}
