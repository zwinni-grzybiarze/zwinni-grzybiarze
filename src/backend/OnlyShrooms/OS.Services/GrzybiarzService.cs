using System.Security.Claims;
using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class GrzybiarzService(IGrzybiarzRepository repository) : IGrzybiarzService
{
    private const int MaxEmailLength = 200;
    private const int MaxNameLength = 100;

    public async Task<Grzybiarz> AddAsync(ClaimsPrincipal userIdentity, CancellationToken cancellationToken = default)
    {
        var email = userIdentity.FindFirst(ClaimTypes.Email)?.Value?.Trim().ToLowerInvariant() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(email) || email.Length > MaxEmailLength)
            throw new ArgumentException("Valid email is required", nameof(userIdentity));

        var emailVerified = userIdentity.FindFirst("email_verified")?.Value;
        if (string.Equals(emailVerified, "false", StringComparison.OrdinalIgnoreCase))
            throw new UnauthorizedAccessException("Adres e-mail konta Google nie jest zweryfikowany.");

        var imie = Truncate(userIdentity.FindFirst(ClaimTypes.GivenName)?.Value?.Trim(), MaxNameLength);
        var nazwisko = Truncate(userIdentity.FindFirst(ClaimTypes.Surname)?.Value?.Trim(), MaxNameLength);
        if (string.IsNullOrWhiteSpace(imie))
            imie = "Google";
        if (string.IsNullOrWhiteSpace(nazwisko))
            nazwisko = "User";

        var existing = await repository.GetByEmailAsync(email, cancellationToken);
        if (existing is not null)
        {
            if (!existing.EmailConfirmed)
            {
                // Unconfirmed registration may be a squat: Google verified mailbox ownership,
                // so drop the unconfirmed password and claim the profile.
                existing.EmailConfirmed = true;
                existing.EmailConfirmationTokenHash = null;
                existing.EmailConfirmationTokenExpiresUtc = null;
                existing.PasswordHash = null;
                existing.PasswordResetTokenHash = null;
                existing.PasswordResetTokenExpiresUtc = null;
                existing.Imie = imie;
                existing.Nazwisko = nazwisko;
                return await repository.UpdateAsync(existing, cancellationToken);
            }

            // Already-confirmed owner: preserve their password and custom profile name;
            // only clean up any leftover confirmation token or fill missing default names.
            var dirty = false;
            if (existing.EmailConfirmationTokenHash is not null || existing.EmailConfirmationTokenExpiresUtc is not null)
            {
                existing.EmailConfirmationTokenHash = null;
                existing.EmailConfirmationTokenExpiresUtc = null;
                dirty = true;
            }
            if (string.IsNullOrWhiteSpace(existing.Imie) || (existing.Imie == "Google" && imie != "Google"))
            {
                existing.Imie = imie;
                dirty = true;
            }
            if (string.IsNullOrWhiteSpace(existing.Nazwisko) || (existing.Nazwisko == "User" && nazwisko != "User"))
            {
                existing.Nazwisko = nazwisko;
                dirty = true;
            }

            return dirty
                ? await repository.UpdateAsync(existing, cancellationToken)
                : existing;
        }

        var grzybiarz = new Grzybiarz
        {
            Email = email,
            Imie = imie,
            Nazwisko = nazwisko,
            EmailConfirmed = true,
        };

        return await repository.AddAsync(grzybiarz, cancellationToken);
    }

    private static string? Truncate(string? value, int maxLength) =>
        string.IsNullOrEmpty(value) || value.Length <= maxLength
            ? value
            : value[..maxLength];

    public Task<Grzybiarz?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
        => repository.GetByEmailAsync(email.Trim().ToLowerInvariant(), cancellationToken);

    public Task<Grzybiarz?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => repository.GetByIdAsync(id, cancellationToken);

    public Task<IReadOnlyList<Grzybiarz>> ListAsync(CancellationToken cancellationToken = default)
        => repository.ListAsync(cancellationToken);
}
