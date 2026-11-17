using System.Security.Claims;
using OS.Model;

namespace OS.Interfaces.Services;

public interface IGrzybiarzService
{
    Task<Grzybiarz> AddAsync(ClaimsPrincipal userIdentity, CancellationToken cancellationToken = default);
    Task<Grzybiarz?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<Grzybiarz?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Grzybiarz>> ListAsync(CancellationToken cancellationToken = default);
}
