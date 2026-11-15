using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class ZadanieService(
    IZadanieRepository repository,
    IGrzybobranieRepository grzybobranieRepository) : IZadanieService
{
    public Task<IReadOnlyList<Zadanie>> GetAllAsync(CancellationToken cancellationToken = default)
        => repository.GetAllAsync(cancellationToken);

    public Task<Zadanie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => repository.GetByIdAsync(id, cancellationToken);

    public async Task<Zadanie> CreateAsync(Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        var normalized = Normalize(zadanie);
        normalized.Id = 0;
        await ValidateGrzybobranieAsync(normalized.GrzybobranieId, cancellationToken);

        return await repository.AddAsync(normalized, cancellationToken);
    }

    public async Task<Zadanie?> UpdateAsync(
        int id,
        Zadanie zadanie,
        CancellationToken cancellationToken = default,
        bool updateGrzybobranieId = true)
    {
        var normalized = Normalize(zadanie);
        normalized.Id = id;

        if (updateGrzybobranieId)
        {
            await ValidateGrzybobranieAsync(normalized.GrzybobranieId, cancellationToken);
        }

        return await repository.UpdateAsync(normalized, cancellationToken, updateGrzybobranieId);
    }

    private async Task ValidateGrzybobranieAsync(int? grzybobranieId, CancellationToken cancellationToken)
    {
        if (grzybobranieId is not int id)
        {
            return;
        }

        if (await grzybobranieRepository.GetByIdAsync(id, cancellationToken) is null)
        {
            throw new ValidationFailedException($"Grzybobranie {id} does not exist.");
        }
    }

    private static Zadanie Normalize(Zadanie source)
    {
        var nazwa = source.Nazwa?.Trim();
        if (string.IsNullOrEmpty(nazwa))
        {
            throw new ValidationFailedException("Nazwa is required.");
        }

        var opis = source.Opis?.Trim();

        return new Zadanie
        {
            Id = source.Id,
            Nazwa = nazwa,
            Opis = string.IsNullOrEmpty(opis) ? null : opis,
            GrzybobranieId = source.GrzybobranieId,
            Status = source.Status,
        };
    }
}
