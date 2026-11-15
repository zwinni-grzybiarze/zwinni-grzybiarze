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

    private static object ValidRequest(string nazwa = "Podgrzybki", string status = "OTWARTE") => new
    {
        nazwa,
        opis = "Potężny opis zadania",
        status,
    };

    private async Task<JsonElement> CreateAsync(object? request = null)
    {
        var response = await _client.PostAsJsonAsync("/api/zadania", request ?? ValidRequest());
        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        return await response.Content.ReadFromJsonAsync<JsonElement>();
    }

    private async Task<int> CreateGrzybobranieAsync(string nazwa)
    {
        var response = await _client.PostAsJsonAsync(
            "/api/grzybobrania",
            new
            {
                nazwa,
                lokalizacja = "Las",
                dataOd = "2026-09-01T08:00:00Z",
                dataDo = "2026-09-01T16:00:00Z",
                status = "PLANOWANE",
            });
        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<JsonElement>();
        return created.GetProperty("grzybobranieId").GetInt32();
    }

    private async Task<JsonElement> CreateLinkedZadanieAsync(int grzybobranieId)
    {
        var response = await _client.PostAsJsonAsync(
            "/api/zadania",
            new
            {
                nazwa = "Zabrać kosz",
                grzybobranieId,
                status = "OTWARTE",
            });
        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        return await response.Content.ReadFromJsonAsync<JsonElement>();
    }

    [TestMethod]
    public async Task Post_CreatesAndReturnsBody()
    {
        var response = await _client.PostAsJsonAsync("/api/zadania", ValidRequest());

        Assert.AreEqual(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var id = body.GetProperty("zadanieId").GetInt32();
        Assert.IsGreaterThan(0, id);
        Assert.EndsWith($"/api/zadania/{id}", response.Headers.Location!.ToString());
        Assert.AreEqual("Podgrzybki", body.GetProperty("nazwa").GetString());
        Assert.AreEqual("Otwarte", body.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Post_CreatesWithoutGrzybobranie()
    {
        var created = await CreateAsync();

        Assert.AreEqual(
            JsonValueKind.Null,
            created.GetProperty("grzybobranieId").ValueKind);
    }

    [TestMethod]
    public async Task Post_WithUnknownGrzybobranieId_Returns400()
    {
        var response = await _client.PostAsJsonAsync(
            "/api/zadania",
            new
            {
                nazwa = "Zadanie z nieznanym grzybobraniem",
                status = "OTWARTE",
                grzybobranieId = int.MaxValue,
            });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    public async Task Put_WithoutGrzybobranieId_PreservesExistingLink()
    {
        var grzybobranieId = await CreateGrzybobranieAsync("Wyprawa zachowaj");
        var created = await CreateLinkedZadanieAsync(grzybobranieId);

        var update = await _client.PutAsJsonAsync(
            $"/api/zadania/{created.GetProperty("zadanieId").GetInt32()}",
            new { nazwa = "Zabrać kosz - zmiana", status = "OTWARTE" });
        Assert.AreEqual(HttpStatusCode.OK, update.StatusCode);
        var updated = await update.Content.ReadFromJsonAsync<JsonElement>();
        Assert.AreEqual(grzybobranieId, updated.GetProperty("grzybobranieId").GetInt32());
    }

    [TestMethod]
    public async Task Put_WithNullGrzybobranieId_UnlinksTask()
    {
        var grzybobranieId = await CreateGrzybobranieAsync("Wyprawa odłącz");
        var created = await CreateLinkedZadanieAsync(grzybobranieId);

        var update = await _client.PutAsJsonAsync(
            $"/api/zadania/{created.GetProperty("zadanieId").GetInt32()}",
            new { nazwa = "Zabrać kosz", status = "OTWARTE", grzybobranieId = (int?)null });
        Assert.AreEqual(HttpStatusCode.OK, update.StatusCode);
        var updated = await update.Content.ReadFromJsonAsync<JsonElement>();
        Assert.AreEqual(JsonValueKind.Null, updated.GetProperty("grzybobranieId").ValueKind);
    }

    [TestMethod]
    public async Task Put_WithGrzybobranieId_ChangesLink()
    {
        var originalId = await CreateGrzybobranieAsync("Wyprawa początkowa");
        var targetId = await CreateGrzybobranieAsync("Wyprawa docelowa");
        var created = await CreateLinkedZadanieAsync(originalId);

        var update = await _client.PutAsJsonAsync(
            $"/api/zadania/{created.GetProperty("zadanieId").GetInt32()}",
            new { nazwa = "Zabrać kosz", status = "OTWARTE", grzybobranieId = targetId });
        Assert.AreEqual(HttpStatusCode.OK, update.StatusCode);
        var updated = await update.Content.ReadFromJsonAsync<JsonElement>();
        Assert.AreEqual(targetId, updated.GetProperty("grzybobranieId").GetInt32());
    }

    [TestMethod]
    public async Task Put_WithUnknownGrzybobranieId_Returns400AndKeepsExistingLink()
    {
        var originalId = await CreateGrzybobranieAsync("Wyprawa zachowaj po błędzie");
        var created = await CreateLinkedZadanieAsync(originalId);

        var update = await _client.PutAsJsonAsync(
            $"/api/zadania/{created.GetProperty("zadanieId").GetInt32()}",
            new
            {
                nazwa = "Zabrać kosz",
                status = "OTWARTE",
                grzybobranieId = int.MaxValue,
            });

        Assert.AreEqual(HttpStatusCode.BadRequest, update.StatusCode);

        var unchanged = await _client.GetFromJsonAsync<JsonElement>(
            $"/api/zadania/{created.GetProperty("zadanieId").GetInt32()}");
        Assert.AreEqual(originalId, unchanged.GetProperty("grzybobranieId").GetInt32());
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
        Assert.AreEqual("Zmieniony", item.GetProperty("nazwa").GetString());
        Assert.AreEqual("Zamknięte", item.GetProperty("status").GetString());
    }

    [TestMethod]
    public async Task Put_UnknownId_Returns404()
    {
        var response = await _client.PutAsJsonAsync("/api/zadania/999999", ValidRequest());

        Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
    }

    [TestMethod]
    public async Task Post_MissingNazwa_Returns400()
    {
        var response = await _client.PostAsJsonAsync("/api/zadania", new
        {
        });

        Assert.AreEqual(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [TestMethod]
    [DataRow("Otwarte")]
    [DataRow("Zamknięte")]
    [DataRow("Zarchiwizowane")]
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
