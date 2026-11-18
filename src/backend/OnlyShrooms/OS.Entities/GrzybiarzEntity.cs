namespace OS.Entities;

public class GrzybiarzEntity
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Imie { get; set; } = string.Empty;
    public string Nazwisko { get; set; } = string.Empty;

    public string? PasswordHash { get; set; }
    public bool EmailConfirmed { get; set; }

    public string? EmailConfirmationTokenHash { get; set; }
    public DateTime? EmailConfirmationTokenExpiresUtc { get; set; }

    public string? PasswordResetTokenHash { get; set; }
    public DateTime? PasswordResetTokenExpiresUtc { get; set; }
}
