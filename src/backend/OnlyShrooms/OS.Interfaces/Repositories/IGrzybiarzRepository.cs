using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IGrzybiarzRepository
{
    Task<Grzybiarz?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<Grzybiarz> AddAsync(Grzybiarz grzybiarz, CancellationToken cancellationToken = default);
}
