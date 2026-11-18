using System.Net;
using System.Net.Sockets;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using OS.Interfaces.Services;
using OS.Repository.DependencyInjection;
using OS.Services.DependencyInjection;
using OS.WebApi.Controllers;
using OS.WebApi.Hubs;
using OS.WebApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        // Enum member names are the wire format (PLANOWANE, W_TOKU, …).
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });
builder.Services.AddSignalR();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ValidationFailedExceptionHandler>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("LocalFrontend", policy =>
        policy
            .SetIsOriginAllowed(origin =>
                Uri.TryCreate(origin, UriKind.Absolute, out var uri)
                && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)
                && uri.IsLoopback)
            .AllowAnyHeader()
            .AllowAnyMethod());
});
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddOsServices();
builder.Services.AddOsRepository(
    builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("Connection string 'Default' is not configured."));
builder.Services.AddSingleton<IAuthEmailLinks, AuthEmailLinks>();

var smtpConfigured =
    !string.IsNullOrWhiteSpace(builder.Configuration["Smtp:Host"])
    && !string.IsNullOrWhiteSpace(builder.Configuration["Smtp:User"])
    && !string.IsNullOrWhiteSpace(builder.Configuration["Smtp:Password"])
    && !string.IsNullOrWhiteSpace(builder.Configuration["Smtp:From"]);

if (smtpConfigured)
    builder.Services.AddSingleton<IEmailSender, SmtpEmailSender>();
else if (builder.Environment.IsDevelopment() || builder.Environment.IsEnvironment("Testing"))
    builder.Services.AddSingleton<IEmailSender, LoggingEmailSender>();
else
    throw new InvalidOperationException(
        "SMTP is not configured. Set Smtp__Host, Smtp__User, Smtp__Password, and Smtp__From.");


builder.Host.UseDefaultServiceProvider(options =>
{
    options.ValidateScopes = true;
    options.ValidateOnBuild = true;
});

var isTesting = builder.Environment.IsEnvironment("Testing");
var authEmailPermitLimit = int.TryParse(builder.Configuration["RateLimiting:AuthEmailPermitLimit"], out var parsedEmailLimit) && parsedEmailLimit > 0
    ? parsedEmailLimit
    : (isTesting ? 200 : 5);
var authLoginPermitLimit = int.TryParse(builder.Configuration["RateLimiting:AuthLoginPermitLimit"], out var parsedLoginLimit) && parsedLoginLimit > 0
    ? parsedLoginLimit
    : (isTesting ? 500 : 15);

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (ctx, ct) =>
    {
        ctx.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        await ctx.HttpContext.Response.WriteAsJsonAsync(
            new { message = "Zbyt wiele prób. Odczekaj chwilę i spróbuj ponownie." },
            cancellationToken: ct);
    };

    options.AddPolicy("auth-email", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ResolveClientIp(httpContext),
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = authEmailPermitLimit,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }));

    options.AddPolicy("auth-login", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ResolveClientIp(httpContext),
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = authLoginPermitLimit,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }));
});

var jwtSecret = builder.Configuration["Jwt:Secret"]
    ?? throw new InvalidOperationException("Jwt:Secret is not configured.");
var jwtSecretBytes = System.Text.Encoding.UTF8.GetBytes(jwtSecret);
if (jwtSecretBytes.Length < 32)
{
    throw new InvalidOperationException(
        "Jwt:Secret must be at least 32 bytes (256 bits) for HMAC-SHA256.");
}
var jwtSigningKey = new SymmetricSecurityKey(jwtSecretBytes);
builder.Services.AddSingleton(jwtSigningKey);
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultSignInScheme = GoogleCookie.Scheme;
    })
    .AddCookie(GoogleCookie.Scheme, options =>
    {
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.None;
        options.ExpireTimeSpan = TimeSpan.FromMinutes(5);
        options.SlidingExpiration = false;
    })
    .AddGoogle("Google", options =>
    {
        options.ClientId = builder.Configuration["Authentication:Google:ClientId"]
                                ?? throw new InvalidOperationException("Google:ClientId is not configured.");
        options.ClientSecret = builder.Configuration["Authentication:Google:ClientSecret"]
                                ?? throw new InvalidOperationException("Google:ClientSecret is not configured.");
        options.SignInScheme = GoogleCookie.Scheme;
        options.CallbackPath = new PathString("/signin-google");
        options.ClaimActions.MapJsonKey("email_verified", "email_verified");
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = "OnlyShrooms.Api",
            ValidAudience = "OnlyShrooms.Api",
            IssuerSigningKey = jwtSigningKey
        };
    });


var app = builder.Build();
await app.Services.MigrateOsDatabaseAsync();

// Configure the HTTP request pipeline.
app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// app.UseHttpsRedirection();

// Showcase / tunnel deploys: never let browsers or Cloudflare keep a stale Flutter shell.
// Previously only index.html was no-cache; main.dart.js / icons kept serving old PWAs after redeploy.
var staticOpts = new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        ctx.Context.Response.Headers.CacheControl = "no-cache, no-store, must-revalidate";
        ctx.Context.Response.Headers.Pragma = "no-cache";
        ctx.Context.Response.Headers.Expires = "0";

        if (ctx.File.Name.Equals("manifest.json", StringComparison.OrdinalIgnoreCase))
        {
            ctx.Context.Response.ContentType = "application/manifest+json";
        }
    },
};

app.UseDefaultFiles();
app.UseStaticFiles(staticOpts);

app.UseCors("LocalFrontend");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");
app.MapFallbackToFile("index.html", staticOpts);

app.Run();

static string ResolveClientIp(HttpContext context)
{
    var remote = context.Connection.RemoteIpAddress;
    if (remote is not null && IsTrustedProxyAddress(remote))
    {
        var cfIp = context.Request.Headers["CF-Connecting-IP"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(cfIp) && IPAddress.TryParse(cfIp.Trim(), out var parsedCfIp))
            return parsedCfIp.ToString();
    }

    return remote?.ToString() ?? "unknown";
}

static bool IsTrustedProxyAddress(IPAddress address)
{
    if (IPAddress.IsLoopback(address))
        return true;

    if (address.IsIPv4MappedToIPv6)
        address = address.MapToIPv4();

    if (address.AddressFamily == AddressFamily.InterNetwork)
    {
        var bytes = address.GetAddressBytes();
        return bytes[0] == 10
            || (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31)
            || (bytes[0] == 192 && bytes[1] == 168);
    }

    if (address.AddressFamily == AddressFamily.InterNetworkV6)
    {
        var bytes = address.GetAddressBytes();
        return (bytes[0] & 0xFE) == 0xFC; // fc00::/7 unique local
    }

    return false;
}

public partial class Program;
