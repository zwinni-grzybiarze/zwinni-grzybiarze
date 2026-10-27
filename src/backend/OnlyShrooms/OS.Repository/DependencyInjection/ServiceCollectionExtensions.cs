using Microsoft.Extensions.DependencyInjection;

namespace OS.Repository.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddOsRepository(this IServiceCollection services)
    {
        return services;
    }
}
