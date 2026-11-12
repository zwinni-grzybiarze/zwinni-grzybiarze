using System.Text.Json.Serialization;
using OS.Repository.DependencyInjection;
using OS.Services.DependencyInjection;
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

builder.Host.UseDefaultServiceProvider(options =>
{
    options.ValidateScopes = true;
    options.ValidateOnBuild = true;
});

var app = builder.Build();

await app.Services.MigrateOsDatabaseAsync();

// Configure the HTTP request pipeline.
app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseDefaultFiles();
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        var path = ctx.File.Name;
        // Keep the shell fresh so PWA clients pick up new service-worker / index after redeploy.
        if (path.Equals("index.html", StringComparison.OrdinalIgnoreCase)
            || path.Equals("flutter_service_worker.js", StringComparison.OrdinalIgnoreCase)
            || path.Equals("manifest.json", StringComparison.OrdinalIgnoreCase)
            || path.Equals("flutter_bootstrap.js", StringComparison.OrdinalIgnoreCase))
        {
            ctx.Context.Response.Headers.CacheControl = "no-cache";
        }

        if (path.Equals("manifest.json", StringComparison.OrdinalIgnoreCase))
        {
            ctx.Context.Response.ContentType = "application/manifest+json";
        }
    },
});

app.UseCors("LocalFrontend");
app.UseAuthorization();

app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");
app.MapFallbackToFile("index.html");

app.Run();

public partial class Program;
