using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class ZadanieService(IZadanieRepository repository) : IZadanieService
{
    public Task<IReadOnlyList<Zadanie>> GetAllAsync(CancellationToken cancellationToken = default)
        => repository.GetAllAsync(cancellationToken);

    public Task<Zadanie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => repository.GetByIdAsync(id, cancellationToken);

    public Task<Zadanie> CreateAsync(Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        var normalized = Normalize(zadanie);
        normalized.Id = 0;

        return repository.AddAsync(normalized, cancellationToken);
    }

    public Task<Zadanie?> UpdateAsync(int id, Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        var normalized = Normalize(zadanie);
        normalized.Id = id;

        return repository.UpdateAsync(normalized, cancellationToken);
    }

    private static Zadanie Normalize(Zadanie source)
    {
        var tytuł = source.Tytuł?.Trim();
        if (string.IsNullOrEmpty(tytuł))
        {
            throw new ValidationFailedException("Tytuł is required.");
        }

        var opis = source.Opis?.Trim();

        return new Zadanie
        {
            Id = source.Id,
            Tytuł = tytuł,
            Opis = string.IsNullOrEmpty(opis) ? null : opis,
            Status = source.Status,
        };
    }
}
