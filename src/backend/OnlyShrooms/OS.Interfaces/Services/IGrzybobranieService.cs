using OS.Model;

namespace OS.Interfaces.Services;

public interface IGrzybobranieService
{
    Task<IReadOnlyList<Grzybobranie>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<Grzybobranie?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<Grzybobranie> CreateAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default);

    Task<Grzybobranie?> UpdateAsync(int id, Grzybobranie grzybobranie, CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
