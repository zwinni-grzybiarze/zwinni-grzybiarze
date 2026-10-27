using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class GrzybobranieService(IGrzybobranieRepository repository) : IGrzybobranieService
{
    public Task<IReadOnlyList<Grzybobranie>> GetAllAsync(CancellationToken cancellationToken = default)
        => repository.GetAllAsync(cancellationToken);

    public Task<Grzybobranie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => repository.GetByIdAsync(id, cancellationToken);

    public Task<Grzybobranie> CreateAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default)
    {
        var normalized = Normalize(grzybobranie);
        normalized.Id = 0;

        return repository.AddAsync(normalized, cancellationToken);
    }

    public Task<Grzybobranie?> UpdateAsync(int id, Grzybobranie grzybobranie, CancellationToken cancellationToken = default)
    {
        var normalized = Normalize(grzybobranie);
        normalized.Id = id;

        return repository.UpdateAsync(normalized, cancellationToken);
    }

    private static Grzybobranie Normalize(Grzybobranie source)
    {
        var nazwa = source.Nazwa?.Trim();
        if (string.IsNullOrEmpty(nazwa))
        {
            throw new ValidationFailedException("Nazwa is required.");
        }

        var lokalizacja = source.Lokalizacja?.Trim();
        if (string.IsNullOrEmpty(lokalizacja))
        {
            throw new ValidationFailedException("Lokalizacja is required.");
        }

        if (source.DataDo < source.DataOd)
        {
            throw new ValidationFailedException("DataDo must not be earlier than DataOd.");
        }

        var opis = source.Opis?.Trim();

        return new Grzybobranie
        {
            Id = source.Id,
            Nazwa = nazwa,
            Opis = string.IsNullOrEmpty(opis) ? null : opis,
            Lokalizacja = lokalizacja,
            DataOd = source.DataOd,
            DataDo = source.DataDo,
            Status = source.Status,
        };
    }
}
