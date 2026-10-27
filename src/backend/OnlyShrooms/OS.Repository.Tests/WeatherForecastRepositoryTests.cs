using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using OS.Model;
using OS.Repository.Repositories;

namespace OS.Repository.Tests;

[TestClass]
public sealed class WeatherForecastRepositoryTests
{
    private SqliteConnection _connection = null!;
    private OsDbContext _context = null!;

    [TestInitialize]
    public async Task Initialize()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();

        var options = new DbContextOptionsBuilder<OsDbContext>().UseSqlite(_connection).Options;
        _context = new OsDbContext(options);
        await _context.Database.MigrateAsync();
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _context.DisposeAsync();
        await _connection.DisposeAsync();
    }

    [TestMethod]
    public async Task AddAsync_AssignsIdAndPersists()
    {
        var repository = new WeatherForecastRepository(_context);

        var added = await repository.AddAsync(new WeatherForecast
        {
            Date = new DateTime(2026, 1, 2, 3, 4, 5, DateTimeKind.Utc),
            TemperatureC = 12,
            Summary = "Cool",
        });

        Assert.IsGreaterThan(0, added.Id);

        var all = await repository.GetAllAsync();
        Assert.HasCount(1, all);
        Assert.AreEqual("Cool", all[0].Summary);
        Assert.AreEqual(12, all[0].TemperatureC);
    }

    [TestMethod]
    public async Task GetAllAsync_ReturnsForecastsOrderedByDate()
    {
        var repository = new WeatherForecastRepository(_context);
        await repository.AddAsync(new WeatherForecast { Date = new DateTime(2026, 1, 3), TemperatureC = 3 });
        await repository.AddAsync(new WeatherForecast { Date = new DateTime(2026, 1, 1), TemperatureC = 1 });

        var all = await repository.GetAllAsync();

        CollectionAssert.AreEqual(new[] { 1, 3 }, all.Select(f => f.TemperatureC).ToArray());
    }
}
