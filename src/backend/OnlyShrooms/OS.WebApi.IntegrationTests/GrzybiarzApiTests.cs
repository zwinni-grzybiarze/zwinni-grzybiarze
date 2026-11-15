using System.Net;

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


    [TestMethod]
    public async Task GetByEmail_UnknownEmail_Returns404()
    {
        var response = await _client.GetAsync("/api/grzybiarze/nieistnieje@example.com");

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task GetByEmail_NoAuthHeader_IsPublic_DoesNotReturn401Or403()
    {
        var response = await _client.GetAsync("/api/grzybiarze/ktos@example.com");

        Assert.AreNotEqual(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.AreNotEqual(HttpStatusCode.Forbidden, response.StatusCode);
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
}
