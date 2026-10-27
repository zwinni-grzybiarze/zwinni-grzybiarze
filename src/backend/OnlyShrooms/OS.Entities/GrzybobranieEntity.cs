namespace OS.Entities;

public class GrzybobranieEntity
{
    public int Id { get; set; }

    public string Nazwa { get; set; } = string.Empty;

    public string? Opis { get; set; }

    public string Lokalizacja { get; set; } = string.Empty;

    public DateTime DataOd { get; set; }

    public DateTime DataDo { get; set; }

    public GrzybobranieStatus Status { get; set; }
}
