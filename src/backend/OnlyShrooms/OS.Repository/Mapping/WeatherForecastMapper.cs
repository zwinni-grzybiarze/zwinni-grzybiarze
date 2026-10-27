using OS.Entities;
using OS.Model;
using Riok.Mapperly.Abstractions;

namespace OS.Repository.Mapping;

[Mapper]
internal static partial class WeatherForecastMapper
{
    public static partial WeatherForecast ToModel(WeatherForecastEntity entity);

    [MapperIgnoreTarget(nameof(WeatherForecastEntity.Id))]
    public static partial WeatherForecastEntity ToNewEntity(WeatherForecast model);

    public static partial void UpdateEntity(WeatherForecast model, WeatherForecastEntity entity);
}
