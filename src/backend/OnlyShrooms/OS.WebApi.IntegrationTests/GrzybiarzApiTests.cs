using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using OS.Interfaces.Repositories;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed partial class GrzybiarzApiTests
{
    private static ApiFactory _factory = null!;
    private HttpClient _client = null!;

    [ClassInitialize]
    public static void ClassInitialize(TestContext _) => _factory = new ApiFactory();

    [ClassCleanup]
    public static void ClassCleanup() => _factory.Dispose();

    [TestInitialize]
    public void Initialize() => _client = _factory.CreateClient(new WebApplicationFactoryClientOptions
    {
        AllowAutoRedirect = false,
    });

    [TestCleanup]
    public void Cleanup() => _client.Dispose();

    [TestMethod]
    public async Task List_Unauthenticated_Returns401()
    {
        var response = await _client.GetAsync("/api/grzybiarze");
        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [TestMethod]
    public async Task GetById_Unauthenticated_Returns401()
    {
        var response = await _client.GetAsync("/api/grzybiarze/1");
        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [TestMethod]
    public async Task GetMe_Unauthenticated_Returns401()
    {
        var response = await _client.GetAsync("/api/grzybiarze/me");
        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [TestMethod]
    public async Task GetMe_Authenticated_UserNotInDatabase_Returns404()
    {
        using var authClient = _factory.CreateAuthenticatedClient("nieznany@example.com");

        var response = await authClient.GetAsync("/api/grzybiarze/me");

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task GetMe_AuthenticatedButNoEmailClaim_Returns401()
    {
        using var authClient = _factory.CreateAuthenticatedClient(email: null);

        var response = await authClient.GetAsync("/api/grzybiarze/me");

        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [TestMethod]
    public async Task List_Authenticated_ExcludesUnconfirmedAndHidesEmails()
    {
        var confirmedEmail = $"lista-{Guid.NewGuid():N}@example.com";
        var unconfirmedEmail = $"spam-{Guid.NewGuid():N}@example.com";
        const string password = "Haslo1234!";

        var jwt = await RegisterConfirmAndLoginAsync(confirmedEmail, password, "Ada", "Potwierdzona");

        var spamRes = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email = unconfirmedEmail,
            password,
            imie = "Spam",
            nazwisko = "Niepotwierdzony",
        });
        Assert.AreEqual(HttpStatusCode.Created, spamRes.StatusCode);

        int unconfirmedId;
        using (var scope = _factory.Services.CreateScope())
        {
            var repo = scope.ServiceProvider.GetRequiredService<IGrzybiarzRepository>();
            var unconfirmed = await repo.GetByEmailAsync(unconfirmedEmail);
            Assert.IsNotNull(unconfirmed);
            unconfirmedId = unconfirmed.Id;
        }

        using var jwtClient = _factory.CreateClient();
        jwtClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwt);

        var response = await jwtClient.GetAsync("/api/grzybiarze");
        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);

        await using var stream = await response.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);
        Assert.AreEqual(JsonValueKind.Array, doc.RootElement.ValueKind);

        var items = doc.RootElement.EnumerateArray().ToList();
        Assert.IsTrue(items.Count >= 1);
        var foundConfirmed = false;
        foreach (var item in items)
        {
            Assert.IsFalse(item.TryGetProperty("email", out _));
            Assert.IsTrue(item.TryGetProperty("grzybiarzId", out var idProp));
            Assert.AreNotEqual(unconfirmedId, idProp.GetInt32());
            if (item.GetProperty("imie").GetString() == "Ada"
                && item.GetProperty("nazwisko").GetString() == "Potwierdzona")
            {
                foundConfirmed = true;
            }
        }
        Assert.IsTrue(foundConfirmed, "Expected confirmed user in /api/grzybiarze list");

        var getUnconfirmed = await jwtClient.GetAsync($"/api/grzybiarze/{unconfirmedId}");
        Assert.AreEqual(HttpStatusCode.NotFound, getUnconfirmed.StatusCode);

        var removedByEmail = await jwtClient.GetAsync($"/api/grzybiarze/by-email/{confirmedEmail}");
        Assert.AreEqual(HttpStatusCode.NotFound, removedByEmail.StatusCode);
    }

    private async Task<string> RegisterConfirmAndLoginAsync(
        string email,
        string password,
        string imie,
        string nazwisko)
    {
        var register = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            imie,
            nazwisko,
        });
        Assert.AreEqual(HttpStatusCode.Created, register.StatusCode);

        var sent = _factory.Emails.LastFor(email);
        Assert.IsNotNull(sent);
        var confirmUri = new Uri(UrlRegex().Match(sent.TextBody).Value);
        var redirect = await _client.GetAsync(confirmUri.PathAndQuery);
        Assert.AreEqual(HttpStatusCode.Redirect, redirect.StatusCode);

        var fragment = redirect.Headers.Location!.Fragment.TrimStart('#');
        var token = Uri.UnescapeDataString(fragment.Split("token=", 2)[1]);

        var confirm = await _client.PostAsJsonAsync("/api/auth/confirm-email", new { token });
        Assert.AreEqual(HttpStatusCode.OK, confirm.StatusCode);

        var login = await _client.PostAsJsonAsync("/api/auth/login", new { email, password });
        Assert.AreEqual(HttpStatusCode.OK, login.StatusCode);
        var body = await login.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("token").GetString()!;
    }

    [GeneratedRegex(@"https?://\S+")]
    private static partial Regex UrlRegex();
}
