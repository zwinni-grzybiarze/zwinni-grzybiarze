using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace OS.WebApiDto;

public class UpdateZadanieRequest
{
    [Required(AllowEmptyStrings = false)]
    [StringLength(200)]
    public string Nazwa { get; set; } = string.Empty;

    [StringLength(10000)]
    public string? Opis { get; set; }

    private int? _grzybobranieId;

    [JsonIgnore]
    public bool GrzybobranieIdSpecified { get; private set; }

    public int? GrzybobranieId
    {
        get => _grzybobranieId;
        set
        {
            _grzybobranieId = value;
            GrzybobranieIdSpecified = true;
        }
    }

    [Required]
    public ZadanieStatusDto? Status { get; set; }
}
