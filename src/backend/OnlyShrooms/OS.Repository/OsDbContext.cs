using Microsoft.EntityFrameworkCore;
using OS.Entities;

namespace OS.Repository;

internal sealed class OsDbContext(DbContextOptions<OsDbContext> options) : DbContext(options)
{
    public DbSet<WeatherForecastEntity> WeatherForecasts => Set<WeatherForecastEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(OsDbContext).Assembly);
    }
}
