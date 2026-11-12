using System.Text.Json.Serialization;

namespace OS.WebApiDto;

public class ZadanieResponse
{
    [JsonPropertyName("zadanieId")]
    public int Id { get; set; }

    public string Nazwa { get; set; } = string.Empty;

    public string? Opis { get; set; }

    public int? GrzybobranieId { get; set; }

    public ZadanieStatusDto Status { get; set; }
}
