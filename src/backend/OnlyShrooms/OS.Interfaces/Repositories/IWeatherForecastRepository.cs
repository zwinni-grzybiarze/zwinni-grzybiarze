using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IWeatherForecastRepository
{
    Task<IReadOnlyList<WeatherForecast>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<WeatherForecast> AddAsync(WeatherForecast forecast, CancellationToken cancellationToken = default);
}
