using System.Text.Json.Serialization;

namespace OS.WebApiDto;

public class GrzybiarzResponse
{
    [JsonPropertyName("grzybiarzId")]
    public int Id { get; set; }
    public string KeycloakId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Imie { get; set; } = string.Empty;
    public string Nazwisko { get; set; } = string.Empty;
}
