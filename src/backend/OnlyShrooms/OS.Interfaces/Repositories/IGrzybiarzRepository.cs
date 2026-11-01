using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IGrzybiarzRepository
{
    Task<Grzybiarz> GetOrCreateAsync(Grzybiarz grzybiarz,
        CancellationToken cancellationToken = default);
}
