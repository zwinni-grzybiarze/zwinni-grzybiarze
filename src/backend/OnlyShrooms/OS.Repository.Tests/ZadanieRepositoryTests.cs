using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using OS.Entities;
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

    private static Zadanie Create(string nazwa = "Kupić śliwki", Model.ZadanieStatus status = Model.ZadanieStatus.Otwarte) => new()
    {
        Nazwa = nazwa,
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
        Assert.AreEqual("Kupić śliwki", loaded.Nazwa);
        Assert.AreEqual("Opis zadania", loaded.Opis);
        Assert.AreEqual(Model.ZadanieStatus.Otwarte, loaded.Status);
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

        added.Nazwa = "Zmieniony tytuł";
        added.Opis = null;
        added.Status = Model.ZadanieStatus.Zamknięte;
        var updated = await _repository.UpdateAsync(added);

        Assert.IsNotNull(updated);
        Assert.AreEqual(added.Id, updated.Id);

        var loaded = await _repository.GetByIdAsync(added.Id);
        Assert.IsNotNull(loaded);
        Assert.AreEqual("Zmieniony tytuł", loaded.Nazwa);
        Assert.IsNull(loaded.Opis);
        Assert.AreEqual(Model.ZadanieStatus.Zamknięte, loaded.Status);
    }

    [TestMethod]
    public async Task UpdateAsync_UnknownId_ReturnsNull()
    {
        var missing = Create();
        missing.Id = 12345;

        Assert.IsNull(await _repository.UpdateAsync(missing));
    }

    [TestMethod]
    public void ZadanieStatus_NamesDoNotExceedDatabaseLimit()
    {
        var statusProperty = _context.Model
            .FindEntityType(typeof(ZadanieEntity))!
            .FindProperty(nameof(ZadanieEntity.Status));

        Assert.IsNotNull(statusProperty);

        var maxLength = statusProperty.GetMaxLength();

        Assert.IsNotNull(maxLength);

        var statusNames = Enum.GetNames<Entities.ZadanieStatus>();

        foreach (var status in statusNames)
        {
            Assert.IsTrue(
                status.Length <= maxLength.Value,
                $"Status '{status}' ma {status.Length} znaków, " +
                $"a maksymalna długość w bazie wynosi {maxLength.Value}."
            );
        }
    }
}
