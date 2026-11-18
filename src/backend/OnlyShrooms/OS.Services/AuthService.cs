using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Mail;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;
using OS.Services.Security;

namespace OS.Services;

public class AuthService(
    SymmetricSecurityKey jwtSigningKey,
    IGrzybiarzRepository grzybiarzRepository,
    IEmailSender emailSender,
    IAuthEmailLinks authEmailLinks) : IAuthService
{
    private const int MaxEmailLength = 200;
    private const int MaxNameLength = 100;
    private static readonly TimeSpan ConfirmTokenLifetime = TimeSpan.FromHours(24);
    private static readonly TimeSpan ResetTokenLifetime = TimeSpan.FromHours(1);

    public string CreateJwt(ClaimsPrincipal claim)
    {
        return WriteToken(claim.Claims);
    }

    public string CreateJwt(Grzybiarz grzybiarz)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, grzybiarz.Id.ToString()),
            new(ClaimTypes.Email, grzybiarz.Email),
            new(ClaimTypes.GivenName, grzybiarz.Imie),
            new(ClaimTypes.Surname, grzybiarz.Nazwisko),
            new(ClaimTypes.Name, $"{grzybiarz.Imie} {grzybiarz.Nazwisko}".Trim()),
        };
        return WriteToken(claims);
    }

    public async Task RegisterAsync(
        string email,
        string password,
        string imie,
        string nazwisko,
        CancellationToken cancellationToken = default)
    {
        email = NormalizeEmail(email);
        imie = (imie ?? string.Empty).Trim();
        nazwisko = (nazwisko ?? string.Empty).Trim();

        if (!IsValidEmail(email))
            throw new ValidationFailedException("Podaj poprawny adres e-mail.");
        PasswordRules.EnsureValid(password);
        if (string.IsNullOrWhiteSpace(imie))
            throw new ValidationFailedException("Imię jest wymagane.");
        if (imie.Length > MaxNameLength)
            throw new ValidationFailedException($"Imię może mieć maksymalnie {MaxNameLength} znaków.");
        if (string.IsNullOrWhiteSpace(nazwisko))
            throw new ValidationFailedException("Nazwisko jest wymagane.");
        if (nazwisko.Length > MaxNameLength)
            throw new ValidationFailedException($"Nazwisko może mieć maksymalnie {MaxNameLength} znaków.");

        var rawToken = TokenHasher.CreateRawToken();
        var passwordHash = PasswordHasher.Hash(password);
        var tokenHash = TokenHasher.Hash(rawToken);
        var tokenExpires = DateTime.UtcNow.Add(ConfirmTokenLifetime);

        var (persisted, created, alreadyConfirmed) = await grzybiarzRepository.UpsertUnconfirmedAsync(
            new Grzybiarz
            {
                Email = email,
                Imie = imie,
                Nazwisko = nazwisko,
                PasswordHash = passwordHash,
                EmailConfirmed = false,
                EmailConfirmationTokenHash = tokenHash,
                EmailConfirmationTokenExpiresUtc = tokenExpires,
            },
            cancellationToken);

        if (alreadyConfirmed)
        {
            // Do not reveal via HTTP status/body that the email is already registered,
            // and never overwrite a confirmed account. Notify the owner best-effort.
            var noticeSubject = "Próba rejestracji w OnlyShrooms";
            var noticeText =
                $"Cześć {persisted.Imie},\n\n" +
                "Otrzymaliśmy prośbę o założenie konta na ten adres e-mail, ale masz już aktywne konto w OnlyShrooms. " +
                "Możesz się zalogować lub skorzystać z opcji resetu hasła.";
            var noticeHtml =
                $"<p>Cześć {WebUtility.HtmlEncode(persisted.Imie)},</p>" +
                "<p>Otrzymaliśmy prośbę o założenie konta na ten adres e-mail, ale masz już aktywne konto w OnlyShrooms.</p>" +
                "<p>Możesz się zalogować lub skorzystać z opcji resetu hasła.</p>";
            try
            {
                await emailSender.SendAsync(persisted.Email, noticeSubject, noticeText, noticeHtml, cancellationToken);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception)
            {
                // Swallow so SMTP errors cannot distinguish confirmed vs unconfirmed emails.
            }
            return;
        }

        var confirmUrl = authEmailLinks.ConfirmEmailApiUrl(rawToken);
        var subject = "Potwierdź konto OnlyShrooms";
        var text = $"Cześć {imie},\n\nPotwierdź rejestrację klikając w link:\n{confirmUrl}\n\nLink jest ważny 24 godziny.";
        var html = $"<p>Cześć {WebUtility.HtmlEncode(imie)},</p><p>Potwierdź rejestrację klikając w link:</p><p><a href=\"{WebUtility.HtmlEncode(confirmUrl)}\">{WebUtility.HtmlEncode(confirmUrl)}</a></p><p>Link jest ważny 24 godziny.</p>";
        try
        {
            await emailSender.SendAsync(email, subject, text, html, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            if (created)
                await grzybiarzRepository.DeleteIfUnconfirmedTokenAsync(persisted.Id, tokenHash, CancellationToken.None);
            throw;
        }
        catch (Exception)
        {
            if (created)
                await grzybiarzRepository.DeleteIfUnconfirmedTokenAsync(persisted.Id, tokenHash, CancellationToken.None);
            throw new ValidationFailedException(
                "Nie udało się wysłać e-maila potwierdzającego. Spróbuj ponownie.");
        }
    }

    public async Task ConfirmEmailAsync(string token, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new ValidationFailedException("Brak tokenu potwierdzenia.");

        var user = await grzybiarzRepository.GetByEmailConfirmationTokenHashAsync(
            TokenHasher.Hash(token),
            cancellationToken);
        if (user is null
            || user.EmailConfirmationTokenExpiresUtc is null
            || user.EmailConfirmationTokenExpiresUtc < DateTime.UtcNow)
        {
            throw new ValidationFailedException("Link potwierdzenia jest nieprawidłowy lub wygasł.");
        }

        // Idempotent within the 24h window so page reloads / duplicate clicks still succeed.
        if (!user.EmailConfirmed)
        {
            user.EmailConfirmed = true;
            await grzybiarzRepository.UpdateAsync(user, cancellationToken);
        }
    }

    public async Task<(string Token, Grzybiarz User)> LoginAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default)
    {
        email = NormalizeEmail(email);
        var user = await grzybiarzRepository.GetByEmailAsync(email, cancellationToken);
        if (user is null
            || string.IsNullOrEmpty(user.PasswordHash)
            || !PasswordHasher.Verify(password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Nieprawidłowy e-mail lub hasło.");
        }

        if (!user.EmailConfirmed)
            throw new UnauthorizedAccessException("Potwierdź adres e-mail przed zalogowaniem.");

        return (CreateJwt(user), user);
    }

    public async Task ForgotPasswordAsync(string email, CancellationToken cancellationToken = default)
    {
        email = NormalizeEmail(email);
        if (!IsValidEmail(email))
            return;

        var user = await grzybiarzRepository.GetByEmailAsync(email, cancellationToken);
        if (user is null)
            return;

        var rawToken = TokenHasher.CreateRawToken();
        user.PasswordResetTokenHash = TokenHasher.Hash(rawToken);
        user.PasswordResetTokenExpiresUtc = DateTime.UtcNow.Add(ResetTokenLifetime);
        await grzybiarzRepository.UpdateAsync(user, cancellationToken);

        var resetUrl = authEmailLinks.ResetPasswordFrontendUrl(rawToken);
        var subject = "Reset hasła OnlyShrooms";
        var text = $"Cześć {user.Imie},\n\nZresetuj hasło klikając w link:\n{resetUrl}\n\nLink jest ważny 1 godzinę. Jeśli nie prosiłeś o reset, zignoruj tę wiadomość.";
        var html = $"<p>Cześć {WebUtility.HtmlEncode(user.Imie)},</p><p>Zresetuj hasło klikając w link:</p><p><a href=\"{WebUtility.HtmlEncode(resetUrl)}\">{WebUtility.HtmlEncode(resetUrl)}</a></p><p>Link jest ważny 1 godzinę.</p>";
        try
        {
            await emailSender.SendAsync(user.Email, subject, text, html, cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception)
        {
            // Swallow SMTP errors so HTTP 500 does not leak whether the email exists.
        }
    }

    public async Task ResetPasswordAsync(
        string token,
        string newPassword,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(token))
            throw new ValidationFailedException("Brak tokenu resetu hasła.");
        PasswordRules.EnsureValid(newPassword);

        var user = await grzybiarzRepository.GetByPasswordResetTokenHashAsync(
            TokenHasher.Hash(token),
            cancellationToken);
        if (user is null
            || user.PasswordResetTokenExpiresUtc is null
            || user.PasswordResetTokenExpiresUtc < DateTime.UtcNow)
        {
            throw new ValidationFailedException("Link resetu hasła jest nieprawidłowy lub wygasł.");
        }

        user.PasswordHash = PasswordHasher.Hash(newPassword);
        user.PasswordResetTokenHash = null;
        user.PasswordResetTokenExpiresUtc = null;
        // Resetting password implies mailbox access — treat as confirmed.
        user.EmailConfirmed = true;
        user.EmailConfirmationTokenHash = null;
        user.EmailConfirmationTokenExpiresUtc = null;
        await grzybiarzRepository.UpdateAsync(user, cancellationToken);
    }

    private string WriteToken(IEnumerable<Claim> claims)
    {
        var credentials = new SigningCredentials(jwtSigningKey, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: "OnlyShrooms.Api",
            audience: "OnlyShrooms.Api",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string NormalizeEmail(string email) =>
        (email ?? string.Empty).Trim().ToLowerInvariant();

    private static bool IsValidEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email)
            || email.Length > MaxEmailLength
            || email.Contains(',')
            || email.Contains(';')
            || email.Contains(' ')
            || email.Contains('\r')
            || email.Contains('\n'))
        {
            return false;
        }

        if (!MailAddress.TryCreate(email, out var parsed)
            || !string.Equals(parsed.Address, email, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var atIndex = email.IndexOf('@');
        return atIndex > 0
            && email.LastIndexOf('@') == atIndex
            && email.IndexOf('.', atIndex + 2) > 0
            && !email.EndsWith('.');
    }
}
