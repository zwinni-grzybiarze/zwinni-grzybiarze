using OS.Model;
using OS.WebApiDto;
using Riok.Mapperly.Abstractions;

namespace OS.WebApi.Mapping;

[Mapper(EnumMappingStrategy = EnumMappingStrategy.ByName)]
internal static partial class GrzybiarzDtoMapper
{
    [MapperIgnoreTarget(nameof(Grzybiarz.Id))]
    public static partial Grzybiarz ToModel(CreateGrzybiarzRequest request);
    public static partial GrzybiarzResponse ToResponse(Grzybiarz model);
}
