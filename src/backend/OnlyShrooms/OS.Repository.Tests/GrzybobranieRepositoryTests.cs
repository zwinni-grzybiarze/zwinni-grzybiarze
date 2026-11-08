using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using OS.Model;
using OS.Repository.Repositories;

namespace OS.Repository.Tests;

[TestClass]
public sealed class GrzybobranieRepositoryTests
{
    private SqliteConnection _connection = null!;
    private OsDbContext _context = null!;
    private GrzybobranieRepository _repository = null!;

    [TestInitialize]
    public async Task Initialize()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        _context = new OsDbContext(options);
        await _context.Database.MigrateAsync();

        _repository = new GrzybobranieRepository(_context);
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _context.DisposeAsync();
        await _connection.DisposeAsync();
    }

    private static Grzybobranie Create(string nazwa = "Borowiki", GrzybobranieStatus status = GrzybobranieStatus.PLANOWANE) => new()
    {
        Nazwa = nazwa,
        Opis = "Opis grzybobrania",
        Lokalizacja = "Las pod Krakowem",
        DataOd = new DateTime(2026, 9, 1, 8, 0, 0, DateTimeKind.Utc),
        DataDo = new DateTime(2026, 9, 1, 16, 30, 0, DateTimeKind.Utc),
        Status = status,
    };

    [TestMethod]
    public async Task AddAsync_AssignsIdAndPersistsAllFields()
    {
        var added = await _repository.AddAsync(Create());

        Assert.IsGreaterThan(0, added.Id);

        var loaded = await _repository.GetByIdAsync(added.Id);
        Assert.IsNotNull(loaded);
        Assert.AreEqual("Borowiki", loaded.Nazwa);
        Assert.AreEqual("Opis grzybobrania", loaded.Opis);
        Assert.AreEqual("Las pod Krakowem", loaded.Lokalizacja);
        Assert.AreEqual(new DateTime(2026, 9, 1, 8, 0, 0, DateTimeKind.Utc), loaded.DataOd);
        Assert.AreEqual(new DateTime(2026, 9, 1, 16, 30, 0, DateTimeKind.Utc), loaded.DataDo);
        Assert.AreEqual(GrzybobranieStatus.PLANOWANE, loaded.Status);
    }

    [TestMethod]
    public async Task GetByIdAsync_ReturnsDatesAsUtc()
    {
        var added = await _repository.AddAsync(Create());

        var loaded = await _repository.GetByIdAsync(added.Id);

        Assert.IsNotNull(loaded);
        Assert.AreEqual(DateTimeKind.Utc, loaded.DataOd.Kind);
        Assert.AreEqual(DateTimeKind.Utc, loaded.DataDo.Kind);
    }

    [TestMethod]
    public async Task GetByIdAsync_UnknownId_ReturnsNull()
    {
        Assert.IsNull(await _repository.GetByIdAsync(12345));
    }

    [TestMethod]
    public async Task GetAllAsync_ReturnsAllItems()
    {
        await _repository.AddAsync(Create("Pierwsze"));
        await _repository.AddAsync(Create("Drugie"));

        var all = await _repository.GetAllAsync();

        CollectionAssert.AreEquivalent(new[] { "Pierwsze", "Drugie" }, all.Select(g => g.Nazwa).ToArray());
    }

    [TestMethod]
    public async Task UpdateAsync_ChangesFieldsAndKeepsId()
    {
        var added = await _repository.AddAsync(Create());

        added.Nazwa = "Zmienione";
        added.Opis = null;
        added.Status = GrzybobranieStatus.W_TOKU;
        added.DataDo = new DateTime(2026, 9, 2, 12, 0, 0, DateTimeKind.Utc);
        var updated = await _repository.UpdateAsync(added);

        Assert.IsNotNull(updated);
        Assert.AreEqual(added.Id, updated.Id);

        var loaded = await _repository.GetByIdAsync(added.Id);
        Assert.IsNotNull(loaded);
        Assert.AreEqual("Zmienione", loaded.Nazwa);
        Assert.IsNull(loaded.Opis);
        Assert.AreEqual(GrzybobranieStatus.W_TOKU, loaded.Status);
        Assert.AreEqual(new DateTime(2026, 9, 2, 12, 0, 0, DateTimeKind.Utc), loaded.DataDo);
    }

    [TestMethod]
    public async Task UpdateAsync_UnknownId_ReturnsNull()
    {
        var missing = Create();
        missing.Id = 12345;

        Assert.IsNull(await _repository.UpdateAsync(missing));
    }

    [TestMethod]
    public async Task Status_IsStoredAsReadableText()
    {
        var added = await _repository.AddAsync(Create(status: GrzybobranieStatus.ZAKONCZONE));

        await using var command = _connection.CreateCommand();
        command.CommandText = "SELECT Status FROM Grzybobrania WHERE Id = $id";
        command.Parameters.AddWithValue("$id", added.Id);

        Assert.AreEqual(GrzybobranieStatus.ZAKONCZONE.ToString(), (string?)await command.ExecuteScalarAsync());
    }
}
