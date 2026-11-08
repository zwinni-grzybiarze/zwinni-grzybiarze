using OS.Model;
using OS.WebApiDto;
using Riok.Mapperly.Abstractions;

namespace OS.WebApi.Mapping;

[Mapper(EnumMappingStrategy = EnumMappingStrategy.ByName)]
internal static partial class ZadanieDtoMapper
{
    public static partial ZadanieResponse ToResponse(Zadanie model);

    [MapperIgnoreTarget(nameof(Zadanie.Id))]
    public static partial Zadanie ToModel(CreateZadanieRequest request);

    [MapperIgnoreTarget(nameof(Zadanie.Id))]
    public static partial Zadanie ToModel(UpdateZadanieRequest request);
}
