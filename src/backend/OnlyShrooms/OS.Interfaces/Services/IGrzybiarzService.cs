using OS.Model;

namespace OS.Interfaces.Services;

public interface IGrzybiarzService
{
    Task<Grzybiarz> GetOrCreateAsync(
        Grzybiarz grzybiarz,
        CancellationToken cancellationToken = default);
}
