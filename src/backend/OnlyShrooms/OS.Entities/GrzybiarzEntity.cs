namespace OS.Entities;

public class GrzybiarzEntity
{
    public int Id { get; set; }
    public string KeycloakId { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string Imie { get; set; } = string.Empty;
    public string Nazwisko { get; set; } = string.Empty;
}
