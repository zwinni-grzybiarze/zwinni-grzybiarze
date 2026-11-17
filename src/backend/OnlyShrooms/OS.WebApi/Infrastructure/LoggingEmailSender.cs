using OS.Interfaces.Services;

namespace OS.WebApi.Infrastructure;

/// <summary>Dev/test fallback that logs messages instead of sending them.</summary>
internal sealed class LoggingEmailSender(ILogger<LoggingEmailSender> logger) : IEmailSender
{
    public Task SendAsync(
        string toEmail,
        string subject,
        string textBody,
        string htmlBody,
        CancellationToken cancellationToken = default)
    {
        logger.LogInformation(
            "Email (log-only) to {To}: {Subject}\n{Body}",
            toEmail,
            subject,
            textBody);
        return Task.CompletedTask;
    }
}
