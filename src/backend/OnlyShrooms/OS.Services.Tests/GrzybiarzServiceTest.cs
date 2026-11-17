using System.Security.Claims;
using Moq;
using OS.Interfaces.Repositories;
using OS.Model;
using OS.Services;

namespace OS.Services.Tests;

[TestClass]
public class GrzybiarzServiceTest
{
    private Mock<IGrzybiarzRepository> _repo = null!;
    private GrzybiarzService _service = null!;

    [TestInitialize]
    public void Initialize()
    {
        _repo = new Mock<IGrzybiarzRepository>();
        _service = new GrzybiarzService(_repo.Object);
    }

    [TestCleanup]
    public void Cleanup()
    {
        _service = null!;
        _repo = null!;
    }

    [TestMethod]
    public async Task AddAsync_ExistingAccount_ConfirmsAndClearsPassword()
    {
        var existing = new Grzybiarz
        {
            Id = 7,
            Email = "victim@example.com",
            Imie = "Atak",
            Nazwisko = "Er",
            PasswordHash = "hash",
            EmailConfirmed = false,
            EmailConfirmationTokenHash = "tok",
            EmailConfirmationTokenExpiresUtc = DateTime.UtcNow.AddHours(1),
            PasswordResetTokenHash = "reset",
            PasswordResetTokenExpiresUtc = DateTime.UtcNow.AddHours(1),
        };

        _repo.Setup(r => r.GetByEmailAsync("victim@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);
        _repo.Setup(r => r.UpdateAsync(It.IsAny<Grzybiarz>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Grzybiarz g, CancellationToken _) => g);

        var identity = new ClaimsPrincipal(new ClaimsIdentity(
        [
            new Claim(ClaimTypes.Email, "Victim@Example.com"),
            new Claim(ClaimTypes.GivenName, "Google"),
            new Claim(ClaimTypes.Surname, "User"),
        ], "Google"));

        var result = await _service.AddAsync(identity);

        Assert.IsTrue(result.EmailConfirmed);
        Assert.IsNull(result.PasswordHash);
        Assert.IsNull(result.EmailConfirmationTokenHash);
        Assert.IsNull(result.EmailConfirmationTokenExpiresUtc);
        Assert.IsNull(result.PasswordResetTokenHash);
        Assert.IsNull(result.PasswordResetTokenExpiresUtc);
        Assert.AreEqual("Google", result.Imie);
        Assert.AreEqual("User", result.Nazwisko);
        _repo.Verify(r => r.UpdateAsync(It.IsAny<Grzybiarz>(), It.IsAny<CancellationToken>()), Times.Once);
        _repo.Verify(r => r.AddAsync(It.IsAny<Grzybiarz>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [TestMethod]
    public async Task AddAsync_ConfirmedAccount_PreservesPasswordAndCustomName()
    {
        var existing = new Grzybiarz
        {
            Id = 8,
            Email = "owner@example.com",
            Imie = "Jan",
            Nazwisko = "Kowalski",
            PasswordHash = "existing-hash",
            EmailConfirmed = true,
        };

        _repo.Setup(r => r.GetByEmailAsync("owner@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(existing);

        var identity = new ClaimsPrincipal(new ClaimsIdentity(
        [
            new Claim(ClaimTypes.Email, "owner@example.com"),
            new Claim("email_verified", "true"),
            new Claim(ClaimTypes.GivenName, "Google"),
            new Claim(ClaimTypes.Surname, "Override"),
        ], "Google"));

        var result = await _service.AddAsync(identity);

        Assert.IsTrue(result.EmailConfirmed);
        Assert.AreEqual("existing-hash", result.PasswordHash);
        Assert.AreEqual("Jan", result.Imie);
        Assert.AreEqual("Kowalski", result.Nazwisko);
        _repo.Verify(r => r.UpdateAsync(It.IsAny<Grzybiarz>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [TestMethod]
    public async Task AddAsync_UnverifiedGoogleEmail_ThrowsUnauthorized()
    {
        var identity = new ClaimsPrincipal(new ClaimsIdentity(
        [
            new Claim(ClaimTypes.Email, "unverified@example.com"),
            new Claim("email_verified", "false"),
        ], "Google"));

        await Assert.ThrowsExactlyAsync<UnauthorizedAccessException>(() => _service.AddAsync(identity));
    }
}
