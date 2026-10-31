using Microsoft.EntityFrameworkCore;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Repository.Mapping;

namespace OS.Repository.Repositories;

internal sealed class ZadanieRepository(OsDbContext context) : IZadanieRepository
{
    public async Task<IReadOnlyList<Zadanie>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var entities = await context.Zadania
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return entities.Select(ZadanieMapper.ToModel).ToList();
    }

    public async Task<Zadanie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await context.Zadania
            .AsNoTracking()
            .SingleOrDefaultAsync(e => e.Id == id, cancellationToken);

        return entity is null ? null : ZadanieMapper.ToModel(entity);
    }

    public async Task<Zadanie> AddAsync(Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        var entity = ZadanieMapper.ToNewEntity(zadanie);
        context.Zadania.Add(entity);
        await context.SaveChangesAsync(cancellationToken);

        return ZadanieMapper.ToModel(entity);
    }

    public async Task<Zadanie?> UpdateAsync(Zadanie zadanie, CancellationToken cancellationToken = default)
    {
        var entity = await context.Zadanie.SingleOrDefaultAsync(e => e.Id == zadanie.Id, cancellationToken);
        if (entity is null)
        {
            return null;
        }

        ZadanieMapper.UpdateEntity(zadanie, entity);
        await context.SaveChangesAsync(cancellationToken);

        return ZadanieMapper.ToModel(entity);
    }
}
