using System.Text.Json.Serialization;

namespace OS.WebApiDto;

public class GrzybiarzPublicResponse
{
    [JsonPropertyName("grzybiarzId")]
    public int Id { get; set; }
    public string Imie { get; set; } = string.Empty;
    public string Nazwisko { get; set; } = string.Empty;
}
