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

    private static Grzybiarz Create(string keycloakId = "test-user") => new()
    {
        KeycloakId = keycloakId,
        Email = "",
        Imie = "Amadeusz",
        Nazwisko = "Mozart",
    };

    [TestMethod]
    public async Task GetOrCreate_ProperModel_CreateNewEntity()
    {
        var grzybiarz = Create();

        var addedGrzybiarz = await _repository.GetOrCreateAsync(grzybiarz);

        Assert.IsNotNull(addedGrzybiarz);
        Assert.AreEqual(grzybiarz.Id, addedGrzybiarz.Id);
        Assert.AreEqual(grzybiarz.KeycloakId, addedGrzybiarz.KeycloakId);
        Assert.AreEqual(grzybiarz.Imie, addedGrzybiarz.Imie);
        Assert.AreEqual(grzybiarz.Nazwisko, addedGrzybiarz.Nazwisko);
        Assert.AreEqual(grzybiarz.Email, addedGrzybiarz.Email);
    }

    [TestMethod]
    public async Task GetOrCreate_DuplicateKeycloakId_ReturnsExistingEntity()
    {
        var grzybiarz = Create();

        var addedGrzybiarz = await _repository.GetOrCreateAsync(grzybiarz);
        var duplicateGrzybiarz = await _repository.GetOrCreateAsync(grzybiarz);

        Assert.IsNotNull(duplicateGrzybiarz);
        Assert.AreEqual(addedGrzybiarz.Id, duplicateGrzybiarz.Id);
        Assert.AreEqual(addedGrzybiarz.KeycloakId, duplicateGrzybiarz.KeycloakId);
        Assert.AreEqual(addedGrzybiarz.Imie, duplicateGrzybiarz.Imie);
        Assert.AreEqual(addedGrzybiarz.Nazwisko, duplicateGrzybiarz.Nazwisko);
        Assert.AreEqual(addedGrzybiarz.Email, duplicateGrzybiarz.Email);
    }

    [TestMethod]
    public async Task GetOrCreate_AddDuplicatedChangedEntity_ReturnsExistingEntity()
    {
        var grzybiarz = Create();

        var addedGrzybiarz = await _repository.GetOrCreateAsync(grzybiarz);
        grzybiarz.Imie = "Jan";
        var duplicateGrzybiarz = await _repository.GetOrCreateAsync(grzybiarz);

        Assert.IsNotNull(duplicateGrzybiarz);
        Assert.AreEqual(addedGrzybiarz.Id, duplicateGrzybiarz.Id);
        Assert.AreNotEqual(duplicateGrzybiarz.Imie, grzybiarz.Imie);
    }

    [TestMethod]
    public async Task GetOrCreate_ConcurrentWrite_WriteNewerEntity()
    {
        var keycloakId = "test-user";
        var first = Create(keycloakId);
        var second = Create(keycloakId);

        second.Imie = "Jan";

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        var repository1 = new GrzybiarzRepository(new OsDbContext(options));
        var repository2 = new GrzybiarzRepository(new OsDbContext(options));

        var results = await Task.WhenAll(
repository1.GetOrCreateAsync(first),
            repository2.GetOrCreateAsync(second)
        );
        Assert.AreEqual(1, await _context.Grzybiarze.CountAsync(x => x.KeycloakId == keycloakId));
        Assert.AreEqual(results[0].Id, results[1].Id);
        Assert.AreEqual(results[0].Imie, results[1].Imie);
    }
}
