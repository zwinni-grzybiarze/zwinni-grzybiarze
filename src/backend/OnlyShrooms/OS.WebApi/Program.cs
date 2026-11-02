using System.Text.Json;
using System.Text.Json.Serialization;
using OS.Repository.DependencyInjection;
using OS.Services.DependencyInjection;
using OS.WebApi.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new JsonStringEnumConverter(JsonNamingPolicy.SnakeCaseUpper));
    });
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ValidationFailedExceptionHandler>();
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

app.UseAuthorization();

app.MapControllers();
app.MapFallbackToFile("index.html");

app.Run();

public partial class Program;
