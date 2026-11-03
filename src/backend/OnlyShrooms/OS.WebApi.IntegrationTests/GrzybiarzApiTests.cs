using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed class GrzybiarzApiTests
{
    private static ApiFactory _factory = null!;
    private HttpClient _client = null!;

    [ClassInitialize]
    public static void ClassInitialize(TestContext _) => _factory = new ApiFactory();

    [ClassCleanup]
    public static void ClassCleanup() => _factory.Dispose();

    [TestInitialize]
    public void Initialize() => _client = _factory.CreateClient();

    [TestCleanup]
    public void Cleanup() => _client.Dispose();

    private static object ValidRequest(
        string keycloakId = "user-123",
        string email = "jan.kowalski@example.com",
        string imie = "Jan",
        string nazwisko = "Kowalski") => new
    {
        keycloakId,
        email,
        imie,
        nazwisko,
    };

    [TestMethod]
    public async Task Post_WithValidAuthentication_ReturnsCreatedUser()
    {
        using var authenticatedClient = _factory.CreateAuthenticatedClient();

        var response = await authenticatedClient.PostAsJsonAsync("/api/auth/me", ValidRequest("auth-user-1"));

        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.AreEqual("auth-user-1", body.GetProperty("keycloakId").GetString());
        Assert.AreEqual("jan.kowalski@example.com", body.GetProperty("email").GetString());
        Assert.AreEqual("Jan", body.GetProperty("imie").GetString());
        Assert.AreEqual("Kowalski", body.GetProperty("nazwisko").GetString());
        Assert.IsTrue(body.TryGetProperty("grzybiarzId", out var grzybiarzId));
        Assert.AreEqual(JsonValueKind.Number, grzybiarzId.ValueKind);
    }

    [TestMethod]
    public async Task Post_WithoutAuthentication_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/me", ValidRequest());

        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [TestMethod]
    public async Task Post_MissingRequiredFieldsWithoutAuthentication_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/me", new
        {
            email = "jan.kowalski@example.com",
            imie = "Jan",
            nazwisko = "Kowalski",
        });

        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
