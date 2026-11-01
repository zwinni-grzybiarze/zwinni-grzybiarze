using OS.Entities;
using OS.Model;
using Riok.Mapperly.Abstractions;

namespace OS.Repository.Mapping;

[Mapper]
internal static partial class GrzybiarzMapper
{
    public static partial Grzybiarz ToModel(GrzybiarzEntity entity);

}
