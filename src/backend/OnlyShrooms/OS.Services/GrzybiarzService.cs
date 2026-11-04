using OS.Interfaces.Repositories;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.Services;

internal sealed class GrzybiarzService(IGrzybiarzRepository repository) : IGrzybiarzService
{
    public Task <Grzybiarz> GetOrCreateAsync(Grzybiarz grzybiarz, CancellationToken cancellationToken = default)
    {
        if(string.IsNullOrWhiteSpace(grzybiarz.KeycloakId))
        {
            throw new ArgumentException("Keycloak subject is required", nameof(grzybiarz.KeycloakId));
        }
        return repository.GetOrCreateAsync(grzybiarz, cancellationToken);
    }
}
