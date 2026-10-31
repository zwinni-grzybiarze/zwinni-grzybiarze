using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using OS.Interfaces.Repositories;
using OS.Repository.Repositories;

namespace OS.Repository.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddOsRepository(this IServiceCollection services, string connectionString)
    {
        services.AddDbContext<OsDbContext>(options => options.UseSqlite(connectionString));
        services.AddScoped<IGrzybobranieRepository, GrzybobranieRepository>();

        return services;
    }

    public static async Task MigrateOsDatabaseAsync(this IServiceProvider serviceProvider, CancellationToken cancellationToken = default)
    {
        await using var scope = serviceProvider.CreateAsyncScope();
        var context = scope.ServiceProvider.GetRequiredService<OsDbContext>();
        EnsureSqliteDirectoryExists(context.Database.GetConnectionString());
        await context.Database.MigrateAsync(cancellationToken);
    }

    private static void EnsureSqliteDirectoryExists(string? connectionString)
    {
        var dataSource = new SqliteConnectionStringBuilder(connectionString).DataSource;
        if (string.IsNullOrWhiteSpace(dataSource) || dataSource.Contains(":memory:", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var directory = Path.GetDirectoryName(Path.GetFullPath(dataSource));
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }
}
