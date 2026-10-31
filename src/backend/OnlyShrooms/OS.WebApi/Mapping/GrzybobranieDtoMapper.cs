using OS.Model;
using OS.WebApiDto;
using Riok.Mapperly.Abstractions;

namespace OS.WebApi.Mapping;

[Mapper(EnumMappingStrategy = EnumMappingStrategy.ByName)]
internal static partial class GrzybobranieDtoMapper
{
    public static partial GrzybobranieResponse ToResponse(Grzybobranie model);

    [MapperIgnoreTarget(nameof(Grzybobranie.Id))]
    public static partial Grzybobranie ToModel(CreateGrzybobranieRequest request);

    [MapperIgnoreTarget(nameof(Grzybobranie.Id))]
    public static partial Grzybobranie ToModel(UpdateGrzybobranieRequest request);

    private static DateTime ToDateTime(DateTime? value) => value ?? default;
}
