using OS.Model;

namespace OS.Interfaces.Repositories;

public interface IGrzybiarzRepository
{
    Task<Grzybiarz?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<Grzybiarz?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Grzybiarz>> ListAsync(CancellationToken cancellationToken = default);
    Task<Grzybiarz?> GetByEmailConfirmationTokenHashAsync(string tokenHash, CancellationToken cancellationToken = default);
    Task<Grzybiarz?> GetByPasswordResetTokenHashAsync(string tokenHash, CancellationToken cancellationToken = default);
    Task<Grzybiarz> AddAsync(Grzybiarz grzybiarz, CancellationToken cancellationToken = default);
    Task<(Grzybiarz User, bool Created, bool AlreadyConfirmed)> UpsertUnconfirmedAsync(Grzybiarz candidate, CancellationToken cancellationToken = default);
    Task<Grzybiarz> UpdateAsync(Grzybiarz grzybiarz, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
    Task DeleteIfUnconfirmedTokenAsync(int id, string expectedTokenHash, CancellationToken cancellationToken = default);
}
