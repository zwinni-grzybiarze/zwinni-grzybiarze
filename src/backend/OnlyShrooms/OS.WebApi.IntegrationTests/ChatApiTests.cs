using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed class ChatApiTests
{
    private static ApiFactory _factory = null!;
    private HttpClient _client = null!;

    [ClassInitialize]
    public static void ClassInitialize(TestContext _) => _factory = new ApiFactory();

    [ClassCleanup]
    public static void ClassCleanup() => _factory.Dispose();

    [TestInitialize]
    public void Initialize() => _client = _factory.CreateClient();

    [TestCleanup]
    public void Cleanup() => _client.Dispose();

    [TestMethod]
    public async Task GetHistory_ReturnsPersistedGlobalMessagesInAscendingOrder()
    {
        await using (var scope = _factory.Services.CreateAsyncScope())
        {
            var chat = scope.ServiceProvider.GetRequiredService<IChatService>();
            await chat.SendAsync(ChatRooms.Global, "u1", "Ala", "pierwsza");
            await chat.SendAsync("other-room", "u1", "Ala", "ukryta");
            await chat.SendAsync(ChatRooms.Global, "u2", "Bartek", "druga");
        }

        var response = await _client.GetAsync($"/api/chat/rooms/{ChatRooms.Global}/messages?limit=50");

        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.AreEqual(JsonValueKind.Array, body.ValueKind);

        var globalMessages = body.EnumerateArray()
            .Where(m => m.GetProperty("roomId").GetString() == ChatRooms.Global)
            .ToList();

        Assert.IsGreaterThanOrEqualTo(2, globalMessages.Count);
        Assert.AreEqual("pierwsza", globalMessages[^2].GetProperty("body").GetString());
        Assert.AreEqual("druga", globalMessages[^1].GetProperty("body").GetString());
        Assert.IsFalse(globalMessages.Any(m => m.GetProperty("body").GetString() == "ukryta"));

        var last = globalMessages[^1];
        Assert.IsFalse(string.IsNullOrWhiteSpace(last.GetProperty("chatMessageId").GetString()));
        Assert.AreEqual("u2", last.GetProperty("senderId").GetString());
        Assert.AreEqual("Bartek", last.GetProperty("senderName").GetString());
    }

    [TestMethod]
    public async Task GetHistory_UnknownRoom_ReturnsEmptyArray()
    {
        var response = await _client.GetAsync("/api/chat/rooms/empty-room-xyz/messages");

        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.AreEqual(JsonValueKind.Array, body.ValueKind);
        Assert.AreEqual(0, body.GetArrayLength());
    }

    [TestMethod]
    public async Task GetHistory_BeforeAndBeforeId_ReturnsOlderPage()
    {
        var roomId = $"room-{Guid.NewGuid():N}";
        ChatMessage first;
        ChatMessage second;

        await using (var scope = _factory.Services.CreateAsyncScope())
        {
            var chat = scope.ServiceProvider.GetRequiredService<IChatService>();
            first = await chat.SendAsync(roomId, "u1", "Ala", "first-msg");
            second = await chat.SendAsync(roomId, "u2", "Bartek", "second-msg");
        }

        // Cursor = newest edge of a limit-1 page (SentAt DESC, Id DESC).
        await using (var scope = _factory.Services.CreateAsyncScope())
        {
            var chat = scope.ServiceProvider.GetRequiredService<IChatService>();
            var newestPage = await chat.GetHistoryAsync(roomId, limit: 1);
            Assert.HasCount(1, newestPage);
            var cursor = newestPage[0];
            var otherId = cursor.Id == first.Id ? second.Id : first.Id;

            var before = Uri.EscapeDataString(cursor.SentAt.ToUniversalTime().ToString("o"));
            var response = await _client.GetAsync(
                $"/api/chat/rooms/{roomId}/messages?before={before}&beforeId={cursor.Id}&limit=50");

            Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
            var body = await response.Content.ReadFromJsonAsync<JsonElement>();
            var ids = body.EnumerateArray()
                .Select(m => m.GetProperty("chatMessageId").GetString())
                .ToHashSet();

            Assert.Contains(otherId.ToString(), ids);
            Assert.DoesNotContain(cursor.Id.ToString(), ids);
        }
    }
}
