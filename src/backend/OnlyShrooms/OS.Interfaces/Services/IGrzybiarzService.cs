using System.Security.Claims;
using OS.Model;

namespace OS.Interfaces.Services;

public interface IGrzybiarzService
{
    Task<Grzybiarz> AddAsync(ClaimsPrincipal userIdentity, CancellationToken cancellationToken = default);
    Task<Grzybiarz?> GetByEmailAsync(string Email, CancellationToken cancellationToken = default);
}
