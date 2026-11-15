using Microsoft.AspNetCore.SignalR;
using OS.Interfaces.Services;
using OS.Model;
using OS.WebApi.Hubs;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed class ChatHubTests
{
    [TestMethod]
    public async Task JoinRoom_RoomIdTooLong_ThrowsHubException()
    {
        var hub = new ChatHub(new ThrowingChatService());
        var tooLong = new string('x', ChatRooms.MaxRoomIdLength + 1);

        var ex = await Assert.ThrowsExactlyAsync<HubException>(() => hub.JoinRoom(tooLong));
        Assert.AreEqual("RoomId is too long.", ex.Message);
    }

    [TestMethod]
    public async Task JoinRoom_BlankRoomId_ThrowsHubException()
    {
        var hub = new ChatHub(new ThrowingChatService());

        var ex = await Assert.ThrowsExactlyAsync<HubException>(() => hub.JoinRoom("   "));
        Assert.AreEqual("RoomId is required.", ex.Message);
    }

    private sealed class ThrowingChatService : IChatService
    {
        public Task<ChatMessage> SendAsync(
            string roomId,
            string senderId,
            string senderName,
            string body,
            CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();

        public Task<IReadOnlyList<ChatMessage>> GetHistoryAsync(
            string roomId,
            DateTime? before = null,
            Guid? beforeId = null,
            int limit = ChatRooms.DefaultHistoryLimit,
            CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();
    }
}
