using OS.Model;
using OS.WebApiDto;
using Riok.Mapperly.Abstractions;

namespace OS.WebApi.Mapping;

[Mapper(EnumMappingStrategy = EnumMappingStrategy.ByName)]
internal static partial class GrzybiarzDtoMapper
{
    [MapperIgnoreTarget(nameof(Grzybiarz.Id))]
    [MapperIgnoreTarget(nameof(Grzybiarz.PasswordHash))]
    [MapperIgnoreTarget(nameof(Grzybiarz.EmailConfirmed))]
    [MapperIgnoreTarget(nameof(Grzybiarz.EmailConfirmationTokenHash))]
    [MapperIgnoreTarget(nameof(Grzybiarz.EmailConfirmationTokenExpiresUtc))]
    [MapperIgnoreTarget(nameof(Grzybiarz.PasswordResetTokenHash))]
    [MapperIgnoreTarget(nameof(Grzybiarz.PasswordResetTokenExpiresUtc))]
    public static partial Grzybiarz ToModel(CreateGrzybiarzRequest request);

    [MapperIgnoreSource(nameof(Grzybiarz.PasswordHash))]
    [MapperIgnoreSource(nameof(Grzybiarz.EmailConfirmed))]
    [MapperIgnoreSource(nameof(Grzybiarz.EmailConfirmationTokenHash))]
    [MapperIgnoreSource(nameof(Grzybiarz.EmailConfirmationTokenExpiresUtc))]
    [MapperIgnoreSource(nameof(Grzybiarz.PasswordResetTokenHash))]
    [MapperIgnoreSource(nameof(Grzybiarz.PasswordResetTokenExpiresUtc))]
    public static partial GrzybiarzResponse ToResponse(Grzybiarz model);

    [MapperIgnoreSource(nameof(Grzybiarz.Email))]
    [MapperIgnoreSource(nameof(Grzybiarz.PasswordHash))]
    [MapperIgnoreSource(nameof(Grzybiarz.EmailConfirmed))]
    [MapperIgnoreSource(nameof(Grzybiarz.EmailConfirmationTokenHash))]
    [MapperIgnoreSource(nameof(Grzybiarz.EmailConfirmationTokenExpiresUtc))]
    [MapperIgnoreSource(nameof(Grzybiarz.PasswordResetTokenHash))]
    [MapperIgnoreSource(nameof(Grzybiarz.PasswordResetTokenExpiresUtc))]
    public static partial GrzybiarzPublicResponse ToPublicResponse(Grzybiarz model);
}
