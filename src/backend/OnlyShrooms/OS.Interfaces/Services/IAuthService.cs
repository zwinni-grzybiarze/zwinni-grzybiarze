using System.Security.Claims;
using OS.Model;

namespace OS.Interfaces.Services;

public interface IAuthService
{
    string CreateJwt(ClaimsPrincipal claim);
    string CreateJwt(Grzybiarz grzybiarz);

    Task RegisterAsync(string email, string password, string imie, string nazwisko, CancellationToken cancellationToken = default);
    Task ConfirmEmailAsync(string token, CancellationToken cancellationToken = default);
    Task<(string Token, Grzybiarz User)> LoginAsync(string email, string password, CancellationToken cancellationToken = default);
    Task ForgotPasswordAsync(string email, CancellationToken cancellationToken = default);
    Task ResetPasswordAsync(string token, string newPassword, CancellationToken cancellationToken = default);
}
