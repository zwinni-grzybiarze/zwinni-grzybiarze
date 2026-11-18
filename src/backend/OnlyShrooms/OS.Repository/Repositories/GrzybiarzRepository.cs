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

    public async Task<(Grzybiarz User, bool Created, bool AlreadyConfirmed)> UpsertUnconfirmedAsync(
        Grzybiarz candidate,
        CancellationToken cancellationToken = default)
    {
        var existing = await context.Grzybiarze
            .SingleOrDefaultAsync(user => user.Email == candidate.Email, cancellationToken);

        if (existing is not null)
        {
            if (existing.EmailConfirmed)
                return (GrzybiarzMapper.ToModel(existing), Created: false, AlreadyConfirmed: true);

            ApplyUnconfirmedRegistration(existing, candidate);
            await context.SaveChangesAsync(cancellationToken);
            return (GrzybiarzMapper.ToModel(existing), Created: false, AlreadyConfirmed: false);
        }

        var entity = GrzybiarzMapper.ToNewEntity(candidate);
        context.Grzybiarze.Add(entity);
        try
        {
            await context.SaveChangesAsync(cancellationToken);
            return (GrzybiarzMapper.ToModel(entity), Created: true, AlreadyConfirmed: false);
        }
        catch (DbUpdateException)
        {
            context.ChangeTracker.Clear();

            var winner = await context.Grzybiarze
                .SingleOrDefaultAsync(user => user.Email == candidate.Email, cancellationToken);
            if (winner is null)
                throw;

            if (winner.EmailConfirmed)
                return (GrzybiarzMapper.ToModel(winner), Created: false, AlreadyConfirmed: true);

            ApplyUnconfirmedRegistration(winner, candidate);
            await context.SaveChangesAsync(cancellationToken);
            return (GrzybiarzMapper.ToModel(winner), Created: false, AlreadyConfirmed: false);
        }
    }

    private static void ApplyUnconfirmedRegistration(GrzybiarzEntity target, Grzybiarz candidate)
    {
        target.Imie = candidate.Imie;
        target.Nazwisko = candidate.Nazwisko;
        target.PasswordHash = candidate.PasswordHash;
        target.EmailConfirmed = false;
        target.EmailConfirmationTokenHash = candidate.EmailConfirmationTokenHash;
        target.EmailConfirmationTokenExpiresUtc = candidate.EmailConfirmationTokenExpiresUtc;
        target.PasswordResetTokenHash = null;
        target.PasswordResetTokenExpiresUtc = null;
    }

    public async Task<Grzybiarz> UpdateAsync(
        Grzybiarz grzybiarz,
        CancellationToken cancellationToken = default)
    {
        var entity = await context.Grzybiarze
            .SingleOrDefaultAsync(user => user.Id == grzybiarz.Id, cancellationToken)
            ?? throw new InvalidOperationException($"Grzybiarz {grzybiarz.Id} not found.");

        entity.Email = grzybiarz.Email;
        entity.Imie = grzybiarz.Imie;
        entity.Nazwisko = grzybiarz.Nazwisko;
        entity.PasswordHash = grzybiarz.PasswordHash;
        entity.EmailConfirmed = grzybiarz.EmailConfirmed;
        entity.EmailConfirmationTokenHash = grzybiarz.EmailConfirmationTokenHash;
        entity.EmailConfirmationTokenExpiresUtc = grzybiarz.EmailConfirmationTokenExpiresUtc;
        entity.PasswordResetTokenHash = grzybiarz.PasswordResetTokenHash;
        entity.PasswordResetTokenExpiresUtc = grzybiarz.PasswordResetTokenExpiresUtc;

        await context.SaveChangesAsync(cancellationToken);
        return GrzybiarzMapper.ToModel(entity);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await context.Grzybiarze
            .SingleOrDefaultAsync(user => user.Id == id, cancellationToken);
        if (entity is null)
            return;

        context.Grzybiarze.Remove(entity);
        await context.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteIfUnconfirmedTokenAsync(
        int id,
        string expectedTokenHash,
        CancellationToken cancellationToken = default)
    {
        var entity = await context.Grzybiarze
            .SingleOrDefaultAsync(
                user => user.Id == id
                    && !user.EmailConfirmed
                    && user.EmailConfirmationTokenHash == expectedTokenHash,
                cancellationToken);
        if (entity is null)
            return;

        context.Grzybiarze.Remove(entity);
        await context.SaveChangesAsync(cancellationToken);
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

    public async Task<Grzybiarz?> GetByIdAsync(
        int id,
        CancellationToken cancellationToken = default)
    {
        var result = await context.Grzybiarze
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.Id == id && user.EmailConfirmed,
                cancellationToken);
        return result is null ? null : GrzybiarzMapper.ToModel(result);
    }

    public async Task<IReadOnlyList<Grzybiarz>> ListAsync(
        CancellationToken cancellationToken = default)
    {
        var entities = await context.Grzybiarze
            .AsNoTracking()
            .Where(user => user.EmailConfirmed)
            .OrderBy(user => user.Nazwisko)
            .ThenBy(user => user.Imie)
            .ToListAsync(cancellationToken);
        return entities.Select(GrzybiarzMapper.ToModel).ToList();
    }

    public async Task<Grzybiarz?> GetByEmailConfirmationTokenHashAsync(
        string tokenHash,
        CancellationToken cancellationToken = default)
    {
        var result = await context.Grzybiarze
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.EmailConfirmationTokenHash == tokenHash,
                cancellationToken);
        return result is null ? null : GrzybiarzMapper.ToModel(result);
    }

    public async Task<Grzybiarz?> GetByPasswordResetTokenHashAsync(
        string tokenHash,
        CancellationToken cancellationToken = default)
    {
        var result = await context.Grzybiarze
            .AsNoTracking()
            .SingleOrDefaultAsync(
                user => user.PasswordResetTokenHash == tokenHash,
                cancellationToken);
        return result is null ? null : GrzybiarzMapper.ToModel(result);
    }
}
