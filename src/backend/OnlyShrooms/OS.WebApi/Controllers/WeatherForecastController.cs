using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Repositories;
using OS.WebApi.Mapping;
using OS.WebApiDto;

namespace OS.WebApi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController(IWeatherForecastRepository repository) : ControllerBase
    {
        [HttpGet(Name = "GetWeatherForecast")]
        public async Task<IEnumerable<WeatherForecastResponse>> Get(CancellationToken cancellationToken)
        {
            var forecasts = await repository.GetAllAsync(cancellationToken);
            return forecasts.Select(WeatherForecastDtoMapper.ToResponse).ToArray();
        }
    }
}
