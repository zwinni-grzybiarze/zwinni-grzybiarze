using OS.Model;

namespace OS.Services.Tests;

[TestClass]
public sealed class GrzybobranieServiceTests
{
    private FakeGrzybobranieRepository _repository = null!;
    private GrzybobranieService _service = null!;

    [TestInitialize]
    public void Initialize()
    {
        _repository = new FakeGrzybobranieRepository();
        _service = new GrzybobranieService(_repository);
    }

    private static Grzybobranie Valid() => new()
    {
        Nazwa = "Borowiki",
        Opis = "Opis",
        Lokalizacja = "Las",
        DataOd = new DateTime(2026, 9, 1, 8, 0, 0, DateTimeKind.Utc),
        DataDo = new DateTime(2026, 9, 1, 16, 0, 0, DateTimeKind.Utc),
        Status = GrzybobranieStatus.Planowane,
    };

    [TestMethod]
    public async Task CreateAsync_TrimsTextAndIgnoresProvidedId()
    {
        var input = Valid();
        input.Id = 99;
        input.Nazwa = "  Borowiki  ";
        input.Lokalizacja = "  Las  ";
        input.Opis = "   ";

        var created = await _service.CreateAsync(input);

        Assert.AreEqual(1, created.Id);
        Assert.AreEqual("Borowiki", created.Nazwa);
        Assert.AreEqual("Las", created.Lokalizacja);
        Assert.IsNull(created.Opis);
    }

    [TestMethod]
    public async Task CreateAsync_AllowsSameStartAndEnd()
    {
        var input = Valid();
        input.DataDo = input.DataOd;

        var created = await _service.CreateAsync(input);

        Assert.AreEqual(created.DataOd, created.DataDo);
    }

    [TestMethod]
    public async Task CreateAsync_EndBeforeStart_Throws()
    {
        var input = Valid();
        input.DataDo = input.DataOd.AddMinutes(-1);

        await Assert.ThrowsExactlyAsync<ValidationFailedException>(() => _service.CreateAsync(input));
        Assert.IsNull(_repository.LastAdded);
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
    [DataRow("")]
    [DataRow("   ")]
    public async Task CreateAsync_BlankLokalizacja_Throws(string lokalizacja)
    {
        var input = Valid();
        input.Lokalizacja = lokalizacja;

        await Assert.ThrowsExactlyAsync<ValidationFailedException>(() => _service.CreateAsync(input));
    }

    [TestMethod]
    public async Task UpdateAsync_UsesRouteIdAndSavesChanges()
    {
        var created = await _service.CreateAsync(Valid());

        var changes = Valid();
        changes.Id = 777;
        changes.Status = GrzybobranieStatus.Odroczone;
        var updated = await _service.UpdateAsync(created.Id, changes);

        Assert.IsNotNull(updated);
        Assert.AreEqual(created.Id, updated.Id);
        Assert.AreEqual(GrzybobranieStatus.Odroczone, updated.Status);
    }

    [TestMethod]
    public async Task UpdateAsync_UnknownId_ReturnsNull()
    {
        Assert.IsNull(await _service.UpdateAsync(404, Valid()));
    }

    [TestMethod]
    public async Task UpdateAsync_EndBeforeStart_ThrowsBeforeTouchingRepository()
    {
        var input = Valid();
        input.DataDo = input.DataOd.AddDays(-1);

        await Assert.ThrowsExactlyAsync<ValidationFailedException>(() => _service.UpdateAsync(1, input));
        Assert.IsNull(_repository.LastUpdated);
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
