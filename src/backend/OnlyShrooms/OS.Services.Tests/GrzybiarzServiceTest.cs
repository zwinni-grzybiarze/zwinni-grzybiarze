using Moq;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Services;

namespace OS.Services.Tests;

[TestClass]
public class GrzybiarzServiceTest
{
    private GrzybiarzService _service = null!;
    private IGrzybiarzRepository _repository = null!;

    [TestInitialize]
    public void Initialize()
    {
        _repository = new Mock<IGrzybiarzRepository>().Object;
        _service = new GrzybiarzService(_repository);
    }

    [TestCleanup]
    public void Cleanup()
    {
        _service = null!;
        _repository = null!;
    }

    [TestMethod]
    public void GetOrCreate_NullKeycloakId_ThrowsArgumentException()
    {
        var grzybiarz = new Grzybiarz
        {
            KeycloakId = null!
        };

        Assert.ThrowsAsync<ArgumentException>(() =>
            _service.GetOrCreateAsync(grzybiarz)
        );
    }
}
