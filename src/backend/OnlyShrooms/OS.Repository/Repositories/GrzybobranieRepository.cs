using Microsoft.EntityFrameworkCore;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Repository.Mapping;

namespace OS.Repository.Repositories;

internal sealed class GrzybobranieRepository(OsDbContext context) : IGrzybobranieRepository
{
    public async Task<IReadOnlyList<Grzybobranie>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var entities = await context.Grzybobrania
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return entities.Select(GrzybobranieMapper.ToModel).ToList();
    }

    public async Task<Grzybobranie?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await context.Grzybobrania
            .AsNoTracking()
            .SingleOrDefaultAsync(e => e.Id == id, cancellationToken);

        return entity is null ? null : GrzybobranieMapper.ToModel(entity);
    }

    public async Task<Grzybobranie> AddAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default)
    {
        var entity = GrzybobranieMapper.ToNewEntity(grzybobranie);
        context.Grzybobrania.Add(entity);
        await context.SaveChangesAsync(cancellationToken);

        return GrzybobranieMapper.ToModel(entity);
    }

    public async Task<Grzybobranie?> UpdateAsync(Grzybobranie grzybobranie, CancellationToken cancellationToken = default)
    {
        var entity = await context.Grzybobrania.SingleOrDefaultAsync(e => e.Id == grzybobranie.Id, cancellationToken);
        if (entity is null)
        {
            return null;
        }

        GrzybobranieMapper.UpdateEntity(grzybobranie, entity);
        await context.SaveChangesAsync(cancellationToken);

        return GrzybobranieMapper.ToModel(entity);
    }
}
