using OS.Entities;
using OS.Model;
using Riok.Mapperly.Abstractions;

namespace OS.Repository.Mapping;

[Mapper(EnumMappingStrategy = EnumMappingStrategy.ByName)]
internal static partial class ZadanieMapper
{
    public static partial Zadanie ToModel(ZadanieEntity entity);

    [MapperIgnoreTarget(nameof(ZadanieEntity.Id))]
    public static partial ZadanieEntity ToNewEntity(Zadanie model);

    [MapperIgnoreTarget(nameof(ZadanieEntity.Id))]
    public static partial void UpdateEntity(Zadanie model, ZadanieEntity entity);
}
