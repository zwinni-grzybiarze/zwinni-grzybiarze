using System.Text.RegularExpressions;
using OS.Model;

namespace OS.Services.Security;

internal static partial class PasswordRules
{
    public const int MinLength = 10;
    public const int MaxLength = 128;

    public const string RequirementsMessage =
        "Hasło musi mieć od 10 do 128 znaków, jedną wielką literę, jedną małą literę, cyfrę i znak specjalny.";

    public static void EnsureValid(string? password)
    {
        if (string.IsNullOrEmpty(password)
            || password.Length < MinLength
            || password.Length > MaxLength
            || !Upper().IsMatch(password)
            || !Lower().IsMatch(password)
            || !Digit().IsMatch(password)
            || !Special().IsMatch(password))
        {
            throw new ValidationFailedException(RequirementsMessage);
        }
    }

    [GeneratedRegex(@"[A-Z]")]
    private static partial Regex Upper();

    [GeneratedRegex(@"[a-z]")]
    private static partial Regex Lower();

    [GeneratedRegex(@"[0-9]")]
    private static partial Regex Digit();

    [GeneratedRegex(@"[^A-Za-z0-9]")]
    private static partial Regex Special();
}
