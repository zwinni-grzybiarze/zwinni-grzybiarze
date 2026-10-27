using Microsoft.Extensions.DependencyInjection;

namespace OS.Services.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddOsServices(this IServiceCollection services)
    {
        return services;
    }
}
