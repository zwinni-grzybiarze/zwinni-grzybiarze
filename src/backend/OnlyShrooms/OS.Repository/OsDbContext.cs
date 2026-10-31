using Microsoft.EntityFrameworkCore;
using OS.Entities;

namespace OS.Repository;

internal sealed class OsDbContext(DbContextOptions<OsDbContext> options) : DbContext(options)
{
    public DbSet<GrzybobranieEntity> Grzybobrania => Set<GrzybobranieEntity>();

    public DbSet<ZadanieEntity> Zadania => Set<ZadanieEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(OsDbContext).Assembly);
    }
}
