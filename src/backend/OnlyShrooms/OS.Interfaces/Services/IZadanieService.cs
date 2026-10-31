using OS.Model;

namespace OS.Interfaces.Services;

public interface IZadanieService
{
    Task<IReadOnlyList<Zadanie>> GetAllAsync(CancellationToken cancellationToken = default);

    Task<Zadanie?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    Task<Zadanie> CreateAsync(Zadanie zadanie, CancellationToken cancellationToken = default);

    Task<Zadanie?> UpdateAsync(int id, Zadanie zadanie, CancellationToken cancellationToken = default);
}
