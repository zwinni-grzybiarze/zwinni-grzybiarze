using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IZadanieRepository
{
    Task<IReadOnlyList<Zadanie>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<Zadanie?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<Zadanie> AddAsync(Zadanie zadanie, CancellationToken cancellationToken = default);

    Task<Zadanie?> UpdateAsync(Zadanie zadanie, CancellationToken cancellationToken = default);
}
