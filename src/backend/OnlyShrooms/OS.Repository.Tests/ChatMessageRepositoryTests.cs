using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using OS.Model;
using OS.Repository.Repositories;

namespace OS.Repository.Tests;

[TestClass]
public sealed class ChatMessageRepositoryTests
{
    private SqliteConnection _connection = null!;
    private OsDbContext _context = null!;
    private ChatMessageRepository _repository = null!;

    [TestInitialize]
    public async Task Initialize()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        _context = new OsDbContext(options);
        await _context.Database.MigrateAsync();

        _repository = new ChatMessageRepository(_context);
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _context.DisposeAsync();
        await _connection.DisposeAsync();
    }

    private static ChatMessage Create(
        string roomId = ChatRooms.Global,
        string body = "cześć",
        DateTime? sentAt = null,
        Guid? id = null) => new()
    {
        Id = id ?? Guid.NewGuid(),
        RoomId = roomId,
        SenderId = "stub-1",
        SenderName = "Jan Kowalski",
        Body = body,
        SentAt = sentAt ?? DateTime.UtcNow,
    };

    [TestMethod]
    public async Task AddAsync_PersistsAndReturnsUtcSentAt()
    {
        var added = await _repository.AddAsync(Create());

        var history = await _repository.GetHistoryAsync(ChatRooms.Global);
        Assert.HasCount(1, history);
        Assert.AreEqual(added.Id, history[0].Id);
        Assert.AreEqual("cześć", history[0].Body);
        Assert.AreEqual(DateTimeKind.Utc, history[0].SentAt.Kind);
    }

    [TestMethod]
    public async Task GetHistoryAsync_FiltersByRoomAndOrdersAscending()
    {
        var t1 = new DateTime(2026, 11, 12, 10, 0, 0, DateTimeKind.Utc);
        var t2 = new DateTime(2026, 11, 12, 10, 1, 0, DateTimeKind.Utc);
        var t3 = new DateTime(2026, 11, 12, 10, 2, 0, DateTimeKind.Utc);

        await _repository.AddAsync(Create(body: "first", sentAt: t1));
        await _repository.AddAsync(Create(roomId: "other", body: "other", sentAt: t2));
        await _repository.AddAsync(Create(body: "second", sentAt: t3));

        var history = await _repository.GetHistoryAsync(ChatRooms.Global);

        Assert.HasCount(2, history);
        Assert.AreEqual("first", history[0].Body);
        Assert.AreEqual("second", history[1].Body);
    }

    [TestMethod]
    public async Task GetHistoryAsync_BeforeCursor_ReturnsOlderMessages()
    {
        var t1 = new DateTime(2026, 11, 12, 10, 0, 0, DateTimeKind.Utc);
        var t2 = new DateTime(2026, 11, 12, 10, 1, 0, DateTimeKind.Utc);
        var t3 = new DateTime(2026, 11, 12, 10, 2, 0, DateTimeKind.Utc);

        await _repository.AddAsync(Create(body: "a", sentAt: t1));
        await _repository.AddAsync(Create(body: "b", sentAt: t2));
        await _repository.AddAsync(Create(body: "c", sentAt: t3));

        var older = await _repository.GetHistoryAsync(ChatRooms.Global, before: t3, limit: 10);

        Assert.HasCount(2, older);
        Assert.AreEqual("a", older[0].Body);
        Assert.AreEqual("b", older[1].Body);
    }

    [TestMethod]
    public async Task GetHistoryAsync_UnspecifiedBefore_TreatedAsUtc()
    {
        var t1 = new DateTime(2026, 11, 12, 10, 0, 0, DateTimeKind.Utc);
        var t2 = new DateTime(2026, 11, 12, 10, 1, 0, DateTimeKind.Utc);

        await _repository.AddAsync(Create(body: "a", sentAt: t1));
        await _repository.AddAsync(Create(body: "b", sentAt: t2));

        var unspecified = new DateTime(2026, 11, 12, 10, 1, 0, DateTimeKind.Unspecified);
        var older = await _repository.GetHistoryAsync(ChatRooms.Global, before: unspecified, limit: 10);

        Assert.HasCount(1, older);
        Assert.AreEqual("a", older[0].Body);
    }

    [TestMethod]
    public async Task GetHistoryAsync_IdenticalSentAtAcrossPageBoundary_UsesBeforeId()
    {
        var sameInstant = new DateTime(2026, 11, 12, 10, 0, 0, DateTimeKind.Utc);
        var idLow = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var idMid = Guid.Parse("00000000-0000-0000-0000-000000000002");
        var idHigh = Guid.Parse("00000000-0000-0000-0000-000000000003");

        await _repository.AddAsync(Create(body: "low", sentAt: sameInstant, id: idLow));
        await _repository.AddAsync(Create(body: "mid", sentAt: sameInstant, id: idMid));
        await _repository.AddAsync(Create(body: "high", sentAt: sameInstant, id: idHigh));

        // Newest-first page of 2: high, mid (ThenByDescending Id)
        var firstPage = await _repository.GetHistoryAsync(ChatRooms.Global, limit: 2);
        Assert.HasCount(2, firstPage);
        Assert.AreEqual("mid", firstPage[0].Body);
        Assert.AreEqual("high", firstPage[1].Body);

        // Next page using composite cursor at the older edge of the first page (mid)
        var secondPage = await _repository.GetHistoryAsync(
            ChatRooms.Global,
            before: sameInstant,
            beforeId: idMid,
            limit: 2);

        Assert.HasCount(1, secondPage);
        Assert.AreEqual("low", secondPage[0].Body);
    }

    [TestMethod]
    public async Task GetHistoryAsync_IdenticalSentAt_WithoutBeforeId_SkipsTie()
    {
        var sameInstant = new DateTime(2026, 11, 12, 10, 0, 0, DateTimeKind.Utc);
        var idLow = Guid.Parse("00000000-0000-0000-0000-000000000001");
        var idHigh = Guid.Parse("00000000-0000-0000-0000-000000000002");

        await _repository.AddAsync(Create(body: "low", sentAt: sameInstant, id: idLow));
        await _repository.AddAsync(Create(body: "high", sentAt: sameInstant, id: idHigh));

        // SentAt-only cursor with strict < drops the other same-timestamp row
        var page = await _repository.GetHistoryAsync(ChatRooms.Global, before: sameInstant, limit: 10);
        Assert.HasCount(0, page);
    }
}
