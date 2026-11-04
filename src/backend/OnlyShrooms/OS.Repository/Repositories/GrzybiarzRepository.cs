using Microsoft.EntityFrameworkCore;
using OS.Entities;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Repository.Mapping;

namespace OS.Repository.Repositories;

internal sealed class GrzybiarzRepository(OsDbContext context)
    : IGrzybiarzRepository
{
    public async Task<Grzybiarz> GetOrCreateAsync(
        Grzybiarz grzybiarz,
        CancellationToken cancellationToken = default)
    {
        var existing = await context.Grzybiarze
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.KeycloakId == grzybiarz.KeycloakId,
                cancellationToken);

        if (existing is not null)
        {
            return GrzybiarzMapper.ToModel(existing);
        }

        var entity = new GrzybiarzEntity
        {
            KeycloakId = grzybiarz.KeycloakId,
            Email = grzybiarz.Email,
            Imie = grzybiarz.Imie,
            Nazwisko = grzybiarz.Nazwisko,
        };

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
                    user => user.KeycloakId == grzybiarz.KeycloakId,
                    cancellationToken);

            if (createdByConcurrentRequest is null)
            {
                throw;
            }

            return GrzybiarzMapper.ToModel(createdByConcurrentRequest);
        }
    }
}
