using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace OS.WebApi.IntegrationTests;

[TestClass]
public sealed class GrzybobranieApiTests
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

    private static object ValidRequest(string nazwa = "Borowiki", string status = "PLANOWANE") => new
    {
        nazwa,
        opis = "Duży opis grzybobrania",
        lokalizacja = "Las pod Krakowem",
        dataOd = "2026-09-01T08:00:00Z",
        dataDo = "2026-09-01T16:00:00Z",
        status,
    };

    private async Task<JsonElement> CreateAsync(object? request = null)
    {
        var response = await _client.PostAsJsonAsync("/api/grzybobrania", request ?? ValidRequest());
        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        return await response.Content.ReadFromJsonAsync<JsonElement>();
    }

    [TestMethod]
    public async Task Post_CreatesAndReturnsLocationAndBody()
    {
        var response = await _client.PostAsJsonAsync("/api/grzybobrania", ValidRequest());

        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var id = body.GetProperty("grzybobranieId").GetInt32();
        Assert.IsGreaterThan(0, id);
        Assert.EndsWith($"/api/grzybobrania/{id}", response.Headers.Location!.ToString());
        Assert.AreEqual("Borowiki", body.GetProperty("nazwa").GetString());
        Assert.AreEqual("PLANOWANE", body.GetProperty("status").GetString());
        Assert.AreEqual("2026-09-01T08:00:00Z", body.GetProperty("dataOd").GetString());
    }

    [TestMethod]
    public async Task Get_ReturnsCreatedItem()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("grzybobranieId").GetInt32();

        var item = await _client.GetFromJsonAsync<JsonElement>($"/api/grzybobrania/{id}");

        Assert.AreEqual("Las pod Krakowem", item.GetProperty("lokalizacja").GetString());
        Assert.AreEqual("Duży opis grzybobrania", item.GetProperty("opis").GetString());
    }

    [TestMethod]
    public async Task GetAll_ReturnsPlainArrayContainingCreatedItem()
    {
        var created = await CreateAsync(ValidRequest("Lista"));
        var id = created.GetProperty("grzybobranieId").GetInt32();

        var list = await _client.GetFromJsonAsync<JsonElement>("/api/grzybobrania");

        Assert.AreEqual(JsonValueKind.Array, list.ValueKind);
        Assert.IsTrue(list.EnumerateArray().Any(i => i.GetProperty("grzybobranieId").GetInt32() == id));
    }

    [TestMethod]
    public async Task Get_UnknownId_Returns404()
    {
        var response = await _client.GetAsync("/api/grzybobrania/999999");

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task Put_UpdatesItem()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("grzybobranieId").GetInt32();

        var response = await _client.PutAsJsonAsync($"/api/grzybobrania/{id}", ValidRequest("Zmienione", "W_TOKU"));

        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
        var item = await _client.GetFromJsonAsync<JsonElement>($"/api/grzybobrania/{id}");
        Assert.AreEqual("Zmienione", item.GetProperty("nazwa").GetString());
        Assert.AreEqual("W_TOKU", item.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Put_UnknownId_Returns404()
    {
        var response = await _client.PutAsJsonAsync("/api/grzybobrania/999999", ValidRequest());

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task Post_MissingNazwa_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/grzybobrania", new
        {
            lokalizacja = "Las",
            dataOd = "2026-09-01T08:00:00Z",
            dataDo = "2026-09-01T16:00:00Z",
        });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    public async Task Post_MissingDates_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/grzybobrania", new { nazwa = "Bez dat", lokalizacja = "Las" });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    public async Task Post_EndBeforeStart_Returns400ProblemDetails()
    {
        var response = await _client.PostAsJsonAsync("/api/grzybobrania", new
        {
            nazwa = "Odwrotne daty",
            lokalizacja = "Las",
            dataOd = "2026-09-02T08:00:00Z",
            dataDo = "2026-09-01T08:00:00Z",
        });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.Content.ReadFromJsonAsync<JsonElement>();
        StringAssert.Contains(problem.GetProperty("detail").GetString(), "DataDo");
    }

    [TestMethod]
    public async Task Put_EndBeforeStart_Returns400()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("grzybobranieId").GetInt32();

        var response = await _client.PutAsJsonAsync($"/api/grzybobrania/{id}", new
        {
            nazwa = "X",
            lokalizacja = "Las",
            dataOd = "2026-09-02T08:00:00Z",
            dataDo = "2026-09-01T08:00:00Z",
            status = "PLANOWANE",
        });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    [DataRow("PLANOWANE")]
    [DataRow("ODROCZONE")]
    [DataRow("W_TOKU")]
    [DataRow("ZAKONCZONE")]
    public async Task Status_RoundTripsAsUpperSnakeCase(string status)
    {
        var created = await CreateAsync(ValidRequest(status: status));

        Assert.AreEqual(status, created.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Delete_IsNotSupported()
    {
        var created = await CreateAsync();
        var id = created.GetProperty("grzybobranieId").GetInt32();

        var response = await _client.DeleteAsync($"/api/grzybobrania/{id}");

        Assert.AreEqual(HttpStatusCode.MethodNotAllowed, response.StatusCode);
    }
}
