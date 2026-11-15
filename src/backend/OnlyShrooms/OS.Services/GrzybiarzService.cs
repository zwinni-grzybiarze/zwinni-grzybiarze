using System.Security.Claims;
using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class GrzybiarzService(IGrzybiarzRepository repository) : IGrzybiarzService
{
    public async Task <Grzybiarz> AddAsync(ClaimsPrincipal userIdentity, CancellationToken cancellationToken = default)
    {

        var grzybiarz = new Grzybiarz
        {
            Email = userIdentity.FindFirst(ClaimTypes.Email)?.Value ?? string.Empty,
            Imie = userIdentity.FindFirst(ClaimTypes.GivenName)?.Value ?? "Google",
            Nazwisko = userIdentity.FindFirst(ClaimTypes.Surname)?.Value ?? "User",
        };
        if(string.IsNullOrWhiteSpace(grzybiarz.Email))
        {
            throw new ArgumentException("Email is required", nameof(grzybiarz.Email));
        }
        return await repository.AddAsync(grzybiarz, cancellationToken);
    }

    public async Task<Grzybiarz?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
        => await repository.GetByEmailAsync(email, cancellationToken);
}
