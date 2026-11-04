using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using OS.Model;
using OS.Repository.Repositories;

namespace OS.Repository.Tests;

[TestClass]
public sealed class ZadanieRepositoryTests
{
    private SqliteConnection _connection = null!;
    private OsDbContext _context = null!;
    private ZadanieRepository _repository = null!;

    [TestInitialize]
    public async Task Initialize()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        _context = new OsDbContext(options);
        await _context.Database.MigrateAsync();

        _repository = new ZadanieRepository(_context);
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _context.DisposeAsync();
        await _connection.DisposeAsync();
    }

    private static Zadanie Create(string tytuł = "Kupić śliwki", ZadanieStatus status = ZadanieStatus.Otwarte) => new()
    {
        Tytuł = tytuł,
        Opis = "Opis zadania",
        Status = status,
    };

    [TestMethod]
    public async Task AddAsync_AssignsIdAndPersistsAllFields()
    {
        var added = await _repository.AddAsync(Create());

        Assert.IsGreaterThan(0, added.Id);

        var loaded = await _repository.GetByIdAsync(added.Id);
        Assert.IsNotNull(loaded);
        Assert.AreEqual("Kupić śliwki", loaded.Tytuł);
        Assert.AreEqual("Opis Zadania", loaded.Opis);
        Assert.AreEqual(ZadanieStatus.Otwarte, loaded.Status);
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

        CollectionAssert.AreEquivalent(new[] { "Pierwsze", "Drugie" }, all.Select(g => g.Tytuł).ToArray());
    }

    [TestMethod]
    public async Task UpdateAsync_ChangesFieldsAndKeepsId()
    {
        var added = await _repository.AddAsync(Create());

        added.Tytuł = "Zmieniony tytuł";
        added.Opis = null;
        added.Status = ZadanieStatus.Zamknięte;
        var updated = await _repository.UpdateAsync(added);

        Assert.IsNotNull(updated);
        Assert.AreEqual(added.Id, updated.Id);

        var loaded = await _repository.GetByIdAsync(added.Id);
        Assert.IsNotNull(loaded);
        Assert.AreEqual("Zmieniony tytuł", loaded.Tytuł);
        Assert.IsNull(loaded.Opis);
        Assert.AreEqual(ZadanieStatus.Zamknięte, loaded.Status);
    }

    [TestMethod]
    public async Task UpdateAsync_UnknownId_ReturnsNull()
    {
        var missing = Create();
        missing.Id = 12345;

        Assert.IsNull(await _repository.UpdateAsync(missing));
    }
}
