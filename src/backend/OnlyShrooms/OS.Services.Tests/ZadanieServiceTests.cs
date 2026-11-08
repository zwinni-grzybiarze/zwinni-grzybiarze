using OS.Model;

namespace OS.Services.Tests;

[TestClass]
public sealed class ZadanieServiceTests
{
    private FakeZadanieRepository _repository = null!;
    private ZadanieService _service = null!;

    [TestInitialize]
    public void Initialize()
    {
        _repository = new FakeZadanieRepository();
        _service = new ZadanieService(_repository);
    }

    private static Zadanie Valid() => new()
    {
        Nazwa = "Maślaki",
        Opis = "Opis",
        Status = ZadanieStatus.Zarchiwizowane,
    };

    [TestMethod]
    public async Task CreateAsync_TrimsTextAndIgnoresProvidedId()
    {
        var input = Valid();
        input.Id = 99;
        input.Nazwa = "  Maślaki  ";
        input.Opis = "   ";

        var created = await _service.CreateAsync(input);

        Assert.AreEqual(1, created.Id);
        Assert.AreEqual("Maślaki", created.Nazwa);
        Assert.IsNull(created.Opis);
    }

    [TestMethod]
    [DataRow("")]
    [DataRow("   ")]
    public async Task CreateAsync_BlankNazwa_Throws(string nazwa)
    {
        var input = Valid();
        input.Nazwa = nazwa;

        await Assert.ThrowsExactlyAsync<ValidationFailedException>(() => _service.CreateAsync(input));
    }

    [TestMethod]
    public async Task UpdateAsync_UsesRouteIdAndSavesChanges()
    {
        var created = await _service.CreateAsync(Valid());

        var changes = Valid();
        changes.Id = 777;
        changes.Opis = "Nowy opis";
        changes.Status = ZadanieStatus.Zamknięte;
        var updated = await _service.UpdateAsync(created.Id, changes);

        Assert.IsNotNull(updated);
        Assert.AreEqual(created.Id, updated.Id);
        Assert.AreEqual("Nowy opis", updated.Opis);
        Assert.AreEqual(ZadanieStatus.Zamknięte, updated.Status);
    }

    [TestMethod]
    public async Task UpdateAsync_UnknownId_ReturnsNull()
    {
        Assert.IsNull(await _service.UpdateAsync(404, Valid()));
    }

    [TestMethod]
    public async Task GetByIdAsync_UnknownId_ReturnsNull()
    {
        Assert.IsNull(await _service.GetByIdAsync(404));
    }

    [TestMethod]
    public async Task GetAllAsync_ReturnsCreatedItems()
    {
        await _service.CreateAsync(Valid());
        await _service.CreateAsync(Valid());

        Assert.HasCount(2, await _service.GetAllAsync());
    }
}
