using Microsoft.EntityFrameworkCore;
using OS.Entities;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Repository.Mapping;

namespace OS.Repository.Repositories;

internal sealed class GrzybiarzRepository(OsDbContext context)
    : IGrzybiarzRepository
{
    public async Task<Grzybiarz> AddAsync(
        Grzybiarz grzybiarz,
        CancellationToken cancellationToken = default)
    {
        var existingGrzybiarz = await GetByEmailAsync(grzybiarz.Email, cancellationToken);
        if (existingGrzybiarz is not null)
        {
            return existingGrzybiarz;
        }

        var entity = GrzybiarzMapper.ToNewEntity(grzybiarz);
        context.Grzybiarze.Add(entity);
        try
        {
            await context.SaveChangesAsync(cancellationToken);
            return GrzybiarzMapper.ToModel(entity);
        }
        catch (DbUpdateException)
        {
            context.ChangeTracker.Clear();

            var createdByConcurrentRequest = await context.Grzybiarze
                .AsNoTracking()
                .SingleOrDefaultAsync(
                    user => user.Email == grzybiarz.Email,
                    cancellationToken);

            if (createdByConcurrentRequest is null)
            {
                throw;
            }

            return GrzybiarzMapper.ToModel(createdByConcurrentRequest);
        }

    }
    public async Task<Grzybiarz?> GetByEmailAsync(
        string email,
        CancellationToken cancellationToken = default)
    {
        var result = await context.Grzybiarze
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.Email == email,
                cancellationToken);
        return result is null ? null : GrzybiarzMapper.ToModel(result);

    }
}
