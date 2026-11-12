using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using OS.Model;
using OS.Repository.Repositories;

namespace OS.Repository.Tests;

[TestClass]
public class GrzybiarzRepositoryTests
{
    private SqliteConnection _connection = null!;
    private OsDbContext _context = null!;
    private GrzybiarzRepository _repository = null!;

    [TestInitialize]
    public async Task Initialize()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        _context = new OsDbContext(options);
        await _context.Database.MigrateAsync();

        _repository = new GrzybiarzRepository(_context);
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _context.DisposeAsync();
        await _connection.DisposeAsync();
    }

    private static Grzybiarz Create() => new()
    {
        Email = "newEmail@com.com",
        Imie = "Amadeusz",
        Nazwisko = "Mozart",
    };

    [TestMethod]
    public async Task GetOrCreate_ProperModel_CreateNewEntity()
    {
        var grzybiarz = Create();

        var addedGrzybiarz = await _repository.AddAsync(grzybiarz);

        Assert.IsNotNull(addedGrzybiarz);
        Assert.AreEqual(grzybiarz.Imie, addedGrzybiarz.Imie);
        Assert.AreEqual(grzybiarz.Nazwisko, addedGrzybiarz.Nazwisko);
        Assert.AreEqual(grzybiarz.Email, addedGrzybiarz.Email);
    }

    [TestMethod]
    public async Task GetOrCreate_AddDuplicatedChangedEntity_ReturnsExistingEntity()
    {
        var grzybiarz = Create();

        var addedGrzybiarz = await _repository.AddAsync(grzybiarz)
                             ?? throw new AssertFailedException("Expected grzybiarz to exist.");
        var duplicate = new Grzybiarz
        {
            Email = addedGrzybiarz.Email,
            Imie = "Andrzej",
            Nazwisko = "Mozart"
        };
        var result = await _repository.GetByEmailAsync(duplicate.Email);

        Assert.IsNotNull(result);
        Assert.AreEqual(result.Email, addedGrzybiarz.Email);
        Assert.AreEqual(result.Id, addedGrzybiarz.Id);
        Assert.AreEqual(result.Imie, addedGrzybiarz.Imie);
    }

    [TestMethod]
    public async Task GetOrCreate_ConcurrentWrite_WriteNewerEntity()
    {
        var first = Create();
        var second = Create();

        second.Imie = "Jan";

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        var repository1 = new GrzybiarzRepository(new OsDbContext(options));
        var repository2 = new GrzybiarzRepository(new OsDbContext(options));

        var results = await Task.WhenAll(
            repository1.AddAsync(first),
            repository2.AddAsync(second)
        );
        var firstResult = results[0] ?? throw new AssertFailedException("First result is null.");
        var secondResult = results[1] ?? throw new AssertFailedException("Second result is null.");

        Assert.AreEqual(1, await _context.Grzybiarze.CountAsync());
        Assert.AreEqual(firstResult.Id, secondResult.Id);
        Assert.AreEqual(firstResult.Imie, secondResult.Imie);
    }
}
