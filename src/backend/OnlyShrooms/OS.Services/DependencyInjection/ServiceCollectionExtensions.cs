using Microsoft.Extensions.DependencyInjection;
using OS.Interfaces.Services;

namespace OS.Services.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddOsServices(this IServiceCollection services)
    {
        services.AddScoped<IGrzybobranieService, GrzybobranieService>();
        services.AddScoped<IGrzybiarzService, GrzybiarzService>();
        services.AddScoped<IAuthService, AuthService>();
        return services;
    }
}
