using OS.Model;
using OS.WebApiDto;
using Riok.Mapperly.Abstractions;

namespace OS.WebApi.Mapping;

[Mapper]
internal static partial class WeatherForecastDtoMapper
{
    [MapperIgnoreSource(nameof(WeatherForecast.Id))]
    public static partial WeatherForecastResponse ToResponse(WeatherForecast model);

    private static DateOnly ToDateOnly(DateTime value) => DateOnly.FromDateTime(value);
}
