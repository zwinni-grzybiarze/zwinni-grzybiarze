using System.Net;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using OS.Interfaces.Repositories;
using OS.Interfaces.Services;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed partial class EmailAuthApiTests
{
    private static ApiFactory _factory = null!;
    private HttpClient _client = null!;

    [ClassInitialize]
    public static void ClassInitialize(TestContext _) => _factory = new ApiFactory();

    [ClassCleanup]
    public static void ClassCleanup() => _factory.Dispose();

    [TestInitialize]
    public void Initialize()
    {
        _client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false,
        });
    }

    [TestCleanup]
    public void Cleanup() => _client.Dispose();

    [TestMethod]
    public async Task Register_GetRedirectDoesNotConsume_PostConfirm_Login_Succeeds()
    {
        var email = $"user-{Guid.NewGuid():N}@example.com";
        const string password = "Haslo1234!";

        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            imie = "Jan",
            nazwisko = "Kowalski",
        });
        Assert.AreEqual(HttpStatusCode.Created, register.StatusCode);

        var confirmUrl = ExtractConfirmApiPath(email);
        var getRedirect = await _client.GetAsync(confirmUrl);
        Assert.AreEqual(HttpStatusCode.Redirect, getRedirect.StatusCode);
        var location = getRedirect.Headers.Location!.ToString();
        Assert.IsTrue(location.Contains("/#/auth/confirmed?token="), location);

        // GET alone (e.g. mail scanner prefetch) must NOT confirm the account.
        var loginAfterGet = await _client.PostAsJsonAsync("/api/auth/login", new { email, password });
        Assert.AreEqual(HttpStatusCode.Unauthorized, loginAfterGet.StatusCode);

        var rawToken = ExtractQueryParamFromHashUrl(location, "token");
        var confirmPost = await _client.PostAsJsonAsync("/api/auth/confirm-email", new { token = rawToken });
        Assert.AreEqual(HttpStatusCode.OK, confirmPost.StatusCode);

        // Repeating POST within validity window is idempotent.
        var confirmPostAgain = await _client.PostAsJsonAsync("/api/auth/confirm-email", new { token = rawToken });
        Assert.AreEqual(HttpStatusCode.OK, confirmPostAgain.StatusCode);

        var login = await _client.PostAsJsonAsync("/api/auth/login", new { email, password });
        Assert.AreEqual(HttpStatusCode.OK, login.StatusCode);
        var body = await login.Content.ReadFromJsonAsync<JsonElement>();
        Assert.IsFalse(string.IsNullOrWhiteSpace(body.GetProperty("token").GetString()));
        Assert.AreEqual(email, body.GetProperty("email").GetString());
    }

    [TestMethod]
    public async Task Register_ConfirmedDuplicateEmail_Returns201WithoutModifyingAccount()
    {
        var email = $"dup-{Guid.NewGuid():N}@example.com";
        const string originalPassword = "Haslo1234!";
        const string attackerPassword = "InneHaslo9!";

        Assert.AreEqual(HttpStatusCode.Created, (await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = originalPassword,
            imie = "Anna",
            nazwisko = "Pierwsza",
        })).StatusCode);

        await ConfirmFromSentEmailAsync(email);

        var dupResponse = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = attackerPassword,
            imie = "Atak",
            nazwisko = "Drugi",
        });
        Assert.AreEqual(HttpStatusCode.Created, dupResponse.StatusCode);

        Assert.AreEqual(HttpStatusCode.Unauthorized,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password = attackerPassword })).StatusCode);
        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password = originalPassword })).StatusCode);

        using var scope = _factory.Services.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<IGrzybiarzRepository>();
        var user = await repo.GetByEmailAsync(email);
        Assert.IsNotNull(user);
        Assert.AreEqual("Anna", user.Imie);
        Assert.AreEqual("Pierwsza", user.Nazwisko);
    }

    [TestMethod]
    public async Task Register_InvalidOrMultiRecipientEmail_Returns400()
    {
        foreach (var badEmail in new[]
        {
            "@",
            "plainaddress",
            "a@b.com, victim@example.com",
            "Display <a@b.com>",
            "user@nodot",
        })
        {
            var res = await _client.PostAsJsonAsync("/api/auth/register", new
            {
                email = badEmail,
                password = "Haslo1234!",
                imie = "Jan",
                nazwisko = "Test",
            });
            Assert.AreEqual(HttpStatusCode.BadRequest, res.StatusCode, $"Expected 400 for '{badEmail}'");
        }
    }

    [TestMethod]
    public async Task Register_UnconfirmedOverwrite_ReplacesPassword()
    {
        var email = $"squat-{Guid.NewGuid():N}@example.com";
        const string attackerPassword = "AtakHaslo1!";
        const string victimPassword = "OfiaraHaslo2!";

        Assert.AreEqual(HttpStatusCode.Created, (await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = attackerPassword,
            imie = "Atak",
            nazwisko = "Er",
        })).StatusCode);

        Assert.AreEqual(HttpStatusCode.Created, (await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = victimPassword,
            imie = "Ofiara",
            nazwisko = "User",
        })).StatusCode);

        await ConfirmFromSentEmailAsync(email);

        Assert.AreEqual(HttpStatusCode.Unauthorized,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password = attackerPassword })).StatusCode);
        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password = victimPassword })).StatusCode);

        using var scope = _factory.Services.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<IGrzybiarzRepository>();
        var user = await repo.GetByEmailAsync(email);
        Assert.IsNotNull(user);
        Assert.AreEqual("Ofiara", user.Imie);
        Assert.AreEqual("User", user.Nazwisko);
    }

    [TestMethod]
    public async Task GoogleLogin_UnconfirmedPasswordAccount_ClearsPasswordHash()
    {
        var email = $"google-merge-{Guid.NewGuid():N}@example.com";
        const string password = "Haslo1234!";

        Assert.AreEqual(HttpStatusCode.Created, (await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            imie = "Atak",
            nazwisko = "Er",
        })).StatusCode);

        using (var scope = _factory.Services.CreateScope())
        {
            var service = scope.ServiceProvider.GetRequiredService<IGrzybiarzService>();
            var identity = new ClaimsPrincipal(new ClaimsIdentity(
            [
                new Claim(ClaimTypes.Email, email),
                new Claim(ClaimTypes.GivenName, "Google"),
                new Claim(ClaimTypes.Surname, "Victim"),
            ],
            authenticationType: "Google"));

            var merged = await service.AddAsync(identity);
            Assert.IsTrue(merged.EmailConfirmed);
            Assert.IsTrue(string.IsNullOrEmpty(merged.PasswordHash));
            Assert.AreEqual("Google", merged.Imie);
            Assert.AreEqual("Victim", merged.Nazwisko);
        }

        Assert.AreEqual(HttpStatusCode.Unauthorized,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password })).StatusCode);
    }

    [TestMethod]
    public async Task GoogleLogin_ConfirmedPasswordAccount_PreservesPasswordAndName()
    {
        var email = $"google-confirmed-{Guid.NewGuid():N}@example.com";
        const string password = "Haslo1234!";

        Assert.AreEqual(HttpStatusCode.Created, (await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            imie = "Kasia",
            nazwisko = "Wlasna",
        })).StatusCode);
        await ConfirmFromSentEmailAsync(email);

        using (var scope = _factory.Services.CreateScope())
        {
            var service = scope.ServiceProvider.GetRequiredService<IGrzybiarzService>();
            var identity = new ClaimsPrincipal(new ClaimsIdentity(
            [
                new Claim(ClaimTypes.Email, email),
                new Claim("email_verified", "true"),
                new Claim(ClaimTypes.GivenName, "GoogleName"),
                new Claim(ClaimTypes.Surname, "GoogleSurname"),
            ],
            authenticationType: "Google"));

            var merged = await service.AddAsync(identity);
            Assert.IsTrue(merged.EmailConfirmed);
            Assert.IsFalse(string.IsNullOrEmpty(merged.PasswordHash));
            Assert.AreEqual("Kasia", merged.Imie);
            Assert.AreEqual("Wlasna", merged.Nazwisko);
        }

        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password })).StatusCode);
    }

    [TestMethod]
    public async Task ForgotPassword_AllowsPasswordAndGoogleUsers_AndAlwaysReturns200()
    {
        var email = $"reset-{Guid.NewGuid():N}@example.com";
        const string password = "Haslo1234!";
        const string newPassword = "NoweHaslo9!x";

        Assert.AreEqual(HttpStatusCode.Created, (await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            imie = "Ewa",
            nazwisko = "Nowak",
        })).StatusCode);
        await ConfirmFromSentEmailAsync(email);

        var forgotUnknown = await _client.PostAsJsonAsync("/api/auth/forgot-password", new { email = "nobody@example.com" });
        Assert.AreEqual(HttpStatusCode.OK, forgotUnknown.StatusCode);

        var forgot = await _client.PostAsJsonAsync("/api/auth/forgot-password", new { email });
        Assert.AreEqual(HttpStatusCode.OK, forgot.StatusCode);

        var resetToken = ExtractResetToken(email);
        var reset = await _client.PostAsJsonAsync("/api/auth/reset-password", new
        {
            token = resetToken,
            newPassword,
        });
        Assert.AreEqual(HttpStatusCode.OK, reset.StatusCode);

        Assert.AreEqual(HttpStatusCode.Unauthorized,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password })).StatusCode);
        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email, password = newPassword })).StatusCode);

        // Google-only user (no password hash yet) can also set a password via forgot-password.
        var googleEmail = $"google-reset-{Guid.NewGuid():N}@example.com";
        using (var scope = _factory.Services.CreateScope())
        {
            var service = scope.ServiceProvider.GetRequiredService<IGrzybiarzService>();
            await service.AddAsync(new ClaimsPrincipal(new ClaimsIdentity(
            [
                new Claim(ClaimTypes.Email, googleEmail),
                new Claim(ClaimTypes.GivenName, "Gosia"),
                new Claim(ClaimTypes.Surname, "Chmura"),
            ], "Google")));
        }

        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/forgot-password", new { email = googleEmail })).StatusCode);
        var googleResetToken = ExtractResetToken(googleEmail);
        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/reset-password", new { token = googleResetToken, newPassword })).StatusCode);
        Assert.AreEqual(HttpStatusCode.OK,
            (await _client.PostAsJsonAsync("/api/auth/login", new { email = googleEmail, password = newPassword })).StatusCode);
    }

    [TestMethod]
    public async Task RateLimiter_AuthEmail_ExceedingPermitLimit_Returns429()
    {
        using var throttledFactory = _factory.WithWebHostBuilder(builder =>
        {
            builder.UseSetting("RateLimiting:AuthEmailPermitLimit", "2");
        });
        using var throttledClient = throttledFactory.CreateClient();

        for (var i = 0; i < 2; i++)
        {
            var ok = await throttledClient.PostAsJsonAsync("/api/auth/forgot-password", new
            {
                email = $"rl-{i}@example.com",
            });
            Assert.AreEqual(HttpStatusCode.OK, ok.StatusCode);
        }

        var limited = await throttledClient.PostAsJsonAsync("/api/auth/forgot-password", new
        {
            email = "rl-3@example.com",
        });
        Assert.AreEqual(HttpStatusCode.TooManyRequests, limited.StatusCode);
    }

    private async Task ConfirmFromSentEmailAsync(string email)
    {
        var confirmPath = ExtractConfirmApiPath(email);
        var redirect = await _client.GetAsync(confirmPath);
        Assert.AreEqual(HttpStatusCode.Redirect, redirect.StatusCode);
        var token = ExtractQueryParamFromHashUrl(redirect.Headers.Location!.ToString(), "token");
        var post = await _client.PostAsJsonAsync("/api/auth/confirm-email", new { token });
        Assert.AreEqual(HttpStatusCode.OK, post.StatusCode);
    }

    private string ExtractConfirmApiPath(string email)
    {
        var sent = _factory.Emails.LastFor(email);
        Assert.IsNotNull(sent, $"Expected confirmation email to {email}");
        var match = UrlRegex().Match(sent.TextBody);
        Assert.IsTrue(match.Success, $"Expected URL in email body:\n{sent.TextBody}");
        var uri = new Uri(match.Value);
        return uri.PathAndQuery;
    }

    private string ExtractResetToken(string email)
    {
        var sent = _factory.Emails.LastFor(email);
        Assert.IsNotNull(sent, $"Expected reset email to {email}");
        var match = UrlRegex().Match(sent.TextBody);
        Assert.IsTrue(match.Success, $"Expected URL in email body:\n{sent.TextBody}");
        return ExtractQueryParamFromHashUrl(match.Value, "token");
    }

    private static string ExtractQueryParamFromHashUrl(string url, string paramName)
    {
        var uri = new Uri(url);
        var fragment = uri.Fragment.TrimStart('#');
        var qIndex = fragment.IndexOf('?');
        Assert.IsTrue(qIndex >= 0, $"Expected query string inside hash fragment of {url}");
        var query = fragment[(qIndex + 1)..];
        foreach (var pair in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = pair.Split('=', 2);
            if (parts.Length == 2 && parts[0] == paramName)
                return Uri.UnescapeDataString(parts[1]);
        }
        Assert.Fail($"Parameter '{paramName}' not found in {url}");
        return string.Empty;
    }

    [GeneratedRegex(@"https?://\S+")]
    private static partial Regex UrlRegex();
}
