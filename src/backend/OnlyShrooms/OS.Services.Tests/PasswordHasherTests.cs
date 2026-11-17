using OS.Model;
using OS.Services.Security;

namespace OS.Services.Tests;

[TestClass]
public class PasswordHasherTests
{
    [TestMethod]
    public void Hash_ThenVerify_Succeeds()
    {
        var hash = PasswordHasher.Hash("Haslo1234!");
        Assert.IsTrue(PasswordHasher.Verify("Haslo1234!", hash));
        Assert.IsFalse(PasswordHasher.Verify("zle", hash));
    }

    [TestMethod]
    public void TokenHasher_RoundTripHash_IsStable()
    {
        var raw = TokenHasher.CreateRawToken();
        Assert.AreEqual(TokenHasher.Hash(raw), TokenHasher.Hash(raw));
        Assert.AreNotEqual(TokenHasher.Hash(raw), TokenHasher.Hash(raw + "x"));
    }

    [TestMethod]
    public void PasswordRules_AcceptsStrongPassword()
    {
        PasswordRules.EnsureValid("Haslo1234!");
    }

    [TestMethod]
    public void PasswordRules_RejectsWeakPasswords()
    {
        Assert.ThrowsExactly<ValidationFailedException>(() => PasswordRules.EnsureValid("short1!A"));
        Assert.ThrowsExactly<ValidationFailedException>(() => PasswordRules.EnsureValid("haslo1234!"));
        Assert.ThrowsExactly<ValidationFailedException>(() => PasswordRules.EnsureValid("HASLO1234!"));
        Assert.ThrowsExactly<ValidationFailedException>(() => PasswordRules.EnsureValid("HasloHaslo!"));
        Assert.ThrowsExactly<ValidationFailedException>(() => PasswordRules.EnsureValid("Haslo12345"));
        Assert.ThrowsExactly<ValidationFailedException>(() => PasswordRules.EnsureValid("Aa1!" + new string('x', 130)));
    }

    [TestMethod]
    public void PasswordHasher_Verify_RejectsOverlongPasswordWithoutHashing()
    {
        var hash = PasswordHasher.Hash("Haslo1234!");
        Assert.IsFalse(PasswordHasher.Verify("Aa1!" + new string('x', 200), hash));
    }
}
