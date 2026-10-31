using System.ComponentModel.DataAnnotations;

namespace OS.WebApiDto;

public class UpdateGrzybobranieRequest
{
    [Required(AllowEmptyStrings = false)]
    [StringLength(200)]
    public string Nazwa { get; set; } = string.Empty;

    [StringLength(10000)]
    public string? Opis { get; set; }

    [Required(AllowEmptyStrings = false)]
    [StringLength(500)]
    public string Lokalizacja { get; set; } = string.Empty;

    [Required]
    public DateTime? DataOd { get; set; }

    [Required]
    public DateTime? DataDo { get; set; }

    public GrzybobranieStatusDto Status { get; set; }
}
