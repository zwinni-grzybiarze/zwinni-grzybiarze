using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OS.Interfaces.Services;
using OS.Model;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(
    IAuthService authService,
    IGrzybiarzService grzybiarzService,
    IConfiguration configuration) : ControllerBase
{
    [AllowAnonymous]
    [HttpGet("google/login")]
    public IActionResult Login()
    {
        var redirectUrl = Url.Action("GoogleCallback", "Auth", null, Request.Scheme);

        return Challenge(
            new AuthenticationProperties { RedirectUri = redirectUrl }, "Google");
    }

    [AllowAnonymous]
    [HttpGet("google/callback")]
    public async Task<IActionResult> GoogleCallback()
    {
        var result = await HttpContext.AuthenticateAsync(GoogleCookie.Scheme);
        if (!result.Succeeded || result.Principal is null)
            return Unauthorized();

        var userIdentity = result.Principal;
        var subject = userIdentity.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(subject))
            return Unauthorized();

        var grzybiarz = await grzybiarzService.AddAsync(userIdentity);

        var jwt = authService.CreateJwt(userIdentity);
        var frontendUrl = configuration["Frontend:Url"]
                          ?? throw new InvalidOperationException("Frontend:Url is not configured.");
        var callbackUrl = $"{frontendUrl}/#/auth/callback?token={WebUtility.UrlEncode(jwt)}&email={WebUtility.UrlEncode(grzybiarz.Email)}";
        return Redirect(callbackUrl);
    }
}
