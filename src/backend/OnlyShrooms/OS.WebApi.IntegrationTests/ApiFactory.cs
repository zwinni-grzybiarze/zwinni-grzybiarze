using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace OS.WebApi.IntegrationTests;

public class ApiFactory : WebApplicationFactory<Program>
{
    private const string TestAuthScheme = "Test";
    private readonly string _databasePath = Path.Combine(Path.GetTempPath(), $"os-tests-{Guid.NewGuid():N}.db");

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.UseSetting("ConnectionStrings:Default", $"Data Source={_databasePath}");
        builder.UseSetting("Jwt:Secret", "dummy-key");
        builder.UseSetting("Authentication:Google:ClientId", "test-google-client-id");
        builder.UseSetting("Authentication:Google:ClientSecret", "test-google-client-secret");

    }


    public HttpClient CreateAuthenticatedClient(string? email = null)
    {
        var factory = new AuthenticatedApiFactory(email);
        return factory.CreateClient();
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);

        if (disposing)
        {
            Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
            foreach (var suffix in new[] { string.Empty, "-wal", "-shm" })
            {
                var path = _databasePath + suffix;
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }
        }
    }

    protected sealed class AuthenticatedApiFactory(string? email = null) : WebApplicationFactory<Program>
    {
        private readonly string _databasePath = Path.Combine(Path.GetTempPath(), $"os-tests-auth-{Guid.NewGuid():N}.db");

        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Testing");
            builder.UseSetting("ConnectionStrings:Default", $"Data Source={_databasePath}");
            builder.UseSetting("Jwt:Secret", "dummy-key");
            builder.UseSetting("Authentication:Google:ClientId", "test-google-client-id");
            builder.UseSetting("Authentication:Google:ClientSecret", "test-google-client-secret");


            builder.ConfigureServices(services =>
            {
                services.AddSingleton(new TestAuthSettings(email));

                services.AddAuthentication(TestAuthScheme)
                    .AddScheme<AuthenticationSchemeOptions, TestAuthHandler>(TestAuthScheme, _ => { });

                services.PostConfigure<AuthenticationOptions>(options =>
                {
                    options.DefaultAuthenticateScheme = TestAuthScheme;
                    options.DefaultChallengeScheme = TestAuthScheme;
                    options.DefaultScheme = TestAuthScheme;
                });

                services.AddAuthorization(options =>
                {
                    options.FallbackPolicy = new AuthorizationPolicyBuilder(TestAuthScheme)
                        .RequireAuthenticatedUser()
                        .Build();
                });
            });
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);

            if (disposing)
            {
                Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
                foreach (var suffix in new[] { string.Empty, "-wal", "-shm" })
                {
                    var path = _databasePath + suffix;
                    if (File.Exists(path))
                    {
                        File.Delete(path);
                    }
                }
            }
        }

        private sealed class TestAuthHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            TestAuthSettings settings)
            : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
        {
            protected override Task<AuthenticateResult> HandleAuthenticateAsync()
            {
                var claims = new List<Claim>
                {
                    new(ClaimTypes.NameIdentifier, "integration-test-user"),
                    new(ClaimTypes.Name, "integration-test-user"),
                };

                if (settings.Email is not null)
                    claims.Add(new Claim(ClaimTypes.Email, settings.Email));

                var identity = new ClaimsIdentity(claims, Scheme.Name);
                var principal = new ClaimsPrincipal(identity);
                var ticket = new AuthenticationTicket(principal, Scheme.Name);

                return Task.FromResult(AuthenticateResult.Success(ticket));
            }
        }
    }

    protected sealed record TestAuthSettings(string? Email);
}
