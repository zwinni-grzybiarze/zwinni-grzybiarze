namespace OS.Model;

public class Zadanie
{
    public int Id { get; set; }

    public string Tytuł { get; set; } = string.Empty;

    public string? Opis { get; set; }
    public ZadanieStatus Status { get; set; }
}
