using System.Net;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using OS.Interfaces.Services;
using OS.Model;
using OS.WebApiDto;

namespace OS.WebApi.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(
    IAuthService authService,
    IGrzybiarzService grzybiarzService,
    IConfiguration configuration) : ControllerBase
{
    [AllowAnonymous]
    [EnableRateLimiting("auth-login")]
    [HttpGet("google/login")]
    public IActionResult Login()
    {
        var redirectUrl = Url.Action("GoogleCallback", "Auth", null, Request.Scheme);

        return Challenge(
            new AuthenticationProperties { RedirectUri = redirectUrl }, "Google");
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth-login")]
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

        Grzybiarz grzybiarz;
        try
        {
            grzybiarz = await grzybiarzService.AddAsync(userIdentity);
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized();
        }

        var jwt = authService.CreateJwt(grzybiarz);
        var frontendUrl = configuration["Frontend:Url"]
                          ?? throw new InvalidOperationException("Frontend:Url is not configured.");
        var callbackUrl = $"{frontendUrl.TrimEnd('/')}/#/auth/callback?token={WebUtility.UrlEncode(jwt)}&email={WebUtility.UrlEncode(grzybiarz.Email)}";
        return Redirect(callbackUrl);
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth-email")]
    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest request,
        CancellationToken cancellationToken)
    {
        await authService.RegisterAsync(
            request.Email,
            request.Password,
            request.Imie,
            request.Nazwisko,
            cancellationToken);
        return StatusCode(StatusCodes.Status201Created, new { message = "Sprawdź skrzynkę e-mail, aby potwierdzić konto." });
    }

    /// <summary>
    /// Safe GET landing for email links: redirects to the SPA without mutating state
    /// so link prefetchers / security scanners cannot consume or auto-confirm tokens.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth-login")]
    [HttpGet("confirm-email")]
    public IActionResult ConfirmEmailRedirect([FromQuery] string? token)
    {
        var frontendUrl = configuration["Frontend:Url"]
                          ?? throw new InvalidOperationException("Frontend:Url is not configured.");
        frontendUrl = frontendUrl.TrimEnd('/');

        if (string.IsNullOrWhiteSpace(token))
            return Redirect($"{frontendUrl}/#/auth/confirmed?error=1");

        return Redirect($"{frontendUrl}/#/auth/confirmed?token={WebUtility.UrlEncode(token)}");
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth-login")]
    [HttpPost("confirm-email")]
    public async Task<IActionResult> ConfirmEmail(
        [FromBody] ConfirmEmailRequest request,
        CancellationToken cancellationToken)
    {
        await authService.ConfirmEmailAsync(request.Token, cancellationToken);
        return Ok(new { message = "Adres e-mail został potwierdzony." });
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth-login")]
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> LoginWithEmail(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var (token, user) = await authService.LoginAsync(request.Email, request.Password, cancellationToken);
            return Ok(new LoginResponse { Token = token, Email = user.Email });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth-email")]
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(
        [FromBody] ForgotPasswordRequest request,
        CancellationToken cancellationToken)
    {
        await authService.ForgotPasswordAsync(request.Email, cancellationToken);
        return Ok(new { message = "Jeśli konto istnieje, wysłaliśmy instrukcję resetu hasła." });
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth-login")]
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(
        [FromBody] ResetPasswordRequest request,
        CancellationToken cancellationToken)
    {
        await authService.ResetPasswordAsync(request.Token, request.NewPassword, cancellationToken);
        return Ok(new { message = "Hasło zostało zmienione. Możesz się zalogować." });
    }
}
