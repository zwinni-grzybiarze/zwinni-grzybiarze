using System.ComponentModel.DataAnnotations;

namespace OS.WebApiDto;

public class CreateGrzybiarzRequest
{
    [Required(AllowEmptyStrings = false)]
    [StringLength(36)]
    public string KeycloakId { get; set; } = string.Empty;

    [Required(AllowEmptyStrings = false)]
    [StringLength(256)]
    public string Email { get; set; } = string.Empty;
    [Required(AllowEmptyStrings = false)]
    [StringLength(100)]
    public string Imie { get; set; } = string.Empty;
    [Required(AllowEmptyStrings = false)]
    [StringLength(100)]
    public string Nazwisko { get; set; } = string.Empty;
}
