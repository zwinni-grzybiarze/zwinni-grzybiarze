using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed class ZadanieApiTests
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

    private static object ValidRequest(string tytuł = "Podgrzybki", string status = "OTWARTE") => new
    {
        tytuł,
        opis = "Potężny opis zadania",
        status,
    };

    private async Task<JsonElement> CreateAsync(object? request = null)
    {
        var response = await _client.PostAsJsonAsync("/api/zadania", request ?? ValidRequest());
        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        return await response.Content.ReadFromJsonAsync<JsonElement>();
    }

    [TestMethod]
    public async Task Post_CreatesAndReturnsLocationAndBody()
    {
        var response = await _client.PostAsJsonAsync("/api/zadania", ValidRequest());

        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var id = body.GetProperty("zadanieId").GetInt32();
        Assert.IsGreaterThan(0, id);
        Assert.EndsWith($"/api/zadania/{id}", response.Headers.Location!.ToString());
        Assert.AreEqual("Podgrzybki", body.GetProperty("tytuł").GetString());
        Assert.AreEqual("OTWARTE", body.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Get_ReturnsCreatedItem()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("zadanieId").GetInt32();

        var item = await _client.GetFromJsonAsync<JsonElement>($"/api/zadania/{id}");

        Assert.AreEqual("Potężny opis zadania", item.GetProperty("opis").GetString());
    }

    [TestMethod]
    public async Task GetAll_ReturnsPlainArrayContainingCreatedItem()
    {
        var created = await CreateAsync(ValidRequest("Lista"));
        var id = created.GetProperty("zadanieId").GetInt32();

        var list = await _client.GetFromJsonAsync<JsonElement>("/api/zadania");

        Assert.AreEqual(JsonValueKind.Array, list.ValueKind);
        Assert.IsTrue(list.EnumerateArray().Any(i => i.GetProperty("zadanieId").GetInt32() == id));
    }

    [TestMethod]
    public async Task Get_UnknownId_Returns404()
    {
        var response = await _client.GetAsync("/api/zadania/999999");

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task Put_UpdatesItem()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("zadanieId").GetInt32();

        var response = await _client.PutAsJsonAsync($"/api/zadania/{id}", ValidRequest("Zmieniony", "ZAMKNIĘTE"));

        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
        var item = await _client.GetFromJsonAsync<JsonElement>($"/api/zadania/{id}");
        Assert.AreEqual("Zmieniony", item.GetProperty("tytuł").GetString());
        Assert.AreEqual("ZAMKNIĘTE", item.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Put_UnknownId_Returns404()
    {
        var response = await _client.PutAsJsonAsync("/api/zadania/999999", ValidRequest());

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task Post_MissingTytuł_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/zadania", new
        {
        });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    [DataRow("OTWARTE")]
    [DataRow("ZAMKNIĘTE")]
    [DataRow("ZARCHIWIZOWANE")]
    public async Task Status_RoundTripsAsUpperSnakeCase(string status)
    {
        var created = await CreateAsync(ValidRequest(status: status));

        Assert.AreEqual(status, created.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Delete_IsNotSupported()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("zadanieId").GetInt32();

        var response = await _client.DeleteAsync($"/api/zadania/{id}");

        Assert.AreEqual(HttpStatusCode.MethodNotAllowed, response.StatusCode);
    }
}
