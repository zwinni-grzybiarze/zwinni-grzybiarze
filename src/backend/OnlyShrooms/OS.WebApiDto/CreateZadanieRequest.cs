using System.ComponentModel.DataAnnotations;

namespace OS.WebApiDto;

public class CreateZadanieRequest
{
    [Required(AllowEmptyStrings = false)]
    [StringLength(200)]
    public string Tytuł { get; set; } = string.Empty;

    [StringLength(10000)]
    public string? Opis { get; set; }
    public ZadanieStatusDto Status { get; set; } = ZadanieStatusDto.Otwarte;
}
