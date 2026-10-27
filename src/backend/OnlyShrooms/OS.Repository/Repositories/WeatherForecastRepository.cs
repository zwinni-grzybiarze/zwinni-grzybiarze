using Microsoft.EntityFrameworkCore;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Repository.Mapping;

namespace OS.Repository.Repositories;

internal sealed class WeatherForecastRepository(OsDbContext context) : IWeatherForecastRepository
{
    public async Task<IReadOnlyList<WeatherForecast>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var entities = await context.WeatherForecasts
            .AsNoTracking()
            .OrderBy(e => e.Date)
            .ThenBy(e => e.Id)
            .ToListAsync(cancellationToken);

        return entities.Select(WeatherForecastMapper.ToModel).ToList();
    }

    public async Task<WeatherForecast> AddAsync(WeatherForecast forecast, CancellationToken cancellationToken = default)
    {
        var entity = WeatherForecastMapper.ToNewEntity(forecast);
        context.WeatherForecasts.Add(entity);
        await context.SaveChangesAsync(cancellationToken);

        return WeatherForecastMapper.ToModel(entity);
    }
}
