using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed class AuthApiTests
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
    public async Task Get_GoogleLogin_RedirectsToGoogle()
    {
        var response = await _client.GetAsync("/api/auth/google/login");

        Assert.AreEqual(HttpStatusCode.Redirect, response.StatusCode);
        Assert.IsNotNull(response.Headers.Location);
        Assert.IsTrue(response.Headers.Location!.ToString().Contains("accounts.google.com"));
    }

    [TestMethod]
    public async Task Get_GoogleCallback_WithoutPrincipal_ReturnsUnauthorized()
    {
        var response = await _client.GetAsync("/api/auth/google/callback");

        Assert.AreEqual(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
