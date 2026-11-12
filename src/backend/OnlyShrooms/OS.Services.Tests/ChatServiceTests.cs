using OS.Model;

namespace OS.Services.Tests;

[TestClass]
public sealed class ChatServiceTests
{
    private FakeChatMessageRepository _repository = null!;
    private ChatService _service = null!;

    [TestInitialize]
    public void Initialize()
    {
        _repository = new FakeChatMessageRepository();
        _service = new ChatService(_repository);
    }

    [TestMethod]
    public async Task SendAsync_PersistsTrimmedMessageWithUtcTimestamp()
    {
        var message = await _service.SendAsync(
            "  global  ",
            "  user-1  ",
            "  Jan Kowalski  ",
            "  cześć  ");

        Assert.AreEqual(ChatRooms.Global, message.RoomId);
        Assert.AreEqual("user-1", message.SenderId);
        Assert.AreEqual("Jan Kowalski", message.SenderName);
        Assert.AreEqual("cześć", message.Body);
        Assert.AreNotEqual(Guid.Empty, message.Id);
        Assert.AreEqual(DateTimeKind.Utc, message.SentAt.Kind);
    }

    [TestMethod]
    public async Task SendAsync_EmptyBody_Throws()
    {
        await Assert.ThrowsExactlyAsync<ValidationFailedException>(() =>
            _service.SendAsync(ChatRooms.Global, "u1", "Jan", "   "));
    }

    [TestMethod]
    public async Task GetHistoryAsync_FiltersByRoomAndRespectsLimit()
    {
        var t1 = new DateTime(2026, 11, 12, 10, 0, 0, DateTimeKind.Utc);
        var t2 = new DateTime(2026, 11, 12, 10, 1, 0, DateTimeKind.Utc);
        var t3 = new DateTime(2026, 11, 12, 10, 2, 0, DateTimeKind.Utc);

        await _repository.AddAsync(new ChatMessage
        {
            Id = Guid.NewGuid(),
            RoomId = ChatRooms.Global,
            SenderId = "u1",
            SenderName = "A",
            Body = "one",
            SentAt = t1,
        });
        await _repository.AddAsync(new ChatMessage
        {
            Id = Guid.NewGuid(),
            RoomId = "other",
            SenderId = "u1",
            SenderName = "A",
            Body = "hidden",
            SentAt = t2,
        });
        await _repository.AddAsync(new ChatMessage
        {
            Id = Guid.NewGuid(),
            RoomId = ChatRooms.Global,
            SenderId = "u2",
            SenderName = "B",
            Body = "two",
            SentAt = t2,
        });
        await _repository.AddAsync(new ChatMessage
        {
            Id = Guid.NewGuid(),
            RoomId = ChatRooms.Global,
            SenderId = "u3",
            SenderName = "C",
            Body = "three",
            SentAt = t3,
        });

        var history = await _service.GetHistoryAsync(ChatRooms.Global, limit: 2);

        Assert.HasCount(2, history);
        Assert.AreEqual("two", history[0].Body);
        Assert.AreEqual("three", history[1].Body);
        Assert.IsTrue(history.All(m => m.RoomId == ChatRooms.Global));
    }
}
