using OS.Entities;
using OS.Model;
using Riok.Mapperly.Abstractions;

namespace OS.Repository.Mapping;

[Mapper(EnumMappingStrategy = EnumMappingStrategy.ByName)]
internal static partial class GrzybobranieMapper
{
    public static partial Grzybobranie ToModel(GrzybobranieEntity entity);

    [MapperIgnoreTarget(nameof(GrzybobranieEntity.Id))]
    public static partial GrzybobranieEntity ToNewEntity(Grzybobranie model);

    [MapperIgnoreTarget(nameof(GrzybobranieEntity.Id))]
    public static partial void UpdateEntity(Grzybobranie model, GrzybobranieEntity entity);
}
