using Microsoft.EntityFrameworkCore;

namespace OS.Repository;

internal sealed class OsDbContext(DbContextOptions<OsDbContext> options) : DbContext(options)
{
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(OsDbContext).Assembly);
    }
}
