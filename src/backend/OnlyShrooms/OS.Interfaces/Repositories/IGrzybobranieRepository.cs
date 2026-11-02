using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IGrzybobranieRepository
{
    Task<IReadOnlyList<Grzybobranie>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<Grzybobranie?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<Grzybobranie> AddAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default);

    Task<Grzybobranie?> UpdateAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
