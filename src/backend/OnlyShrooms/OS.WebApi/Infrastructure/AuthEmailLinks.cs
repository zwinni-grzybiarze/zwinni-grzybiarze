using System.Net;
using OS.Interfaces.Services;

namespace OS.WebApi.Infrastructure;

internal sealed class AuthEmailLinks(IConfiguration configuration) : IAuthEmailLinks
{
    public string ConfirmEmailApiUrl(string rawToken)
    {
        var publicBase = configuration["PublicApi:Url"]
            ?? configuration["Frontend:Url"]
            ?? throw new InvalidOperationException("Frontend:Url is not configured.");
        publicBase = publicBase.TrimEnd('/');
        return $"{publicBase}/api/auth/confirm-email?token={WebUtility.UrlEncode(rawToken)}";
    }

    public string ResetPasswordFrontendUrl(string rawToken)
    {
        var frontendUrl = configuration["Frontend:Url"]
            ?? throw new InvalidOperationException("Frontend:Url is not configured.");
        frontendUrl = frontendUrl.TrimEnd('/');
        return $"{frontendUrl}/#/auth/reset-password?token={WebUtility.UrlEncode(rawToken)}";
    }
}
