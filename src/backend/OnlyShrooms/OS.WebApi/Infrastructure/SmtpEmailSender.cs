using System.Net;
using System.Net.Mail;
using System.Net.Mime;
using System.Text;
using OS.Interfaces.Services;

namespace OS.WebApi.Infrastructure;

/// <summary>Sends mail via SMTP (e.g. Mailgun SMTP user + password).</summary>
internal sealed class SmtpEmailSender(
    IConfiguration configuration,
    ILogger<SmtpEmailSender> logger) : IEmailSender
{
    private static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(10);

    public async Task SendAsync(
        string toEmail,
        string subject,
        string textBody,
        string htmlBody,
        CancellationToken cancellationToken = default)
    {
        var host = configuration["Smtp:Host"]
            ?? throw new InvalidOperationException("Smtp:Host is not configured.");
        var user = configuration["Smtp:User"]
            ?? throw new InvalidOperationException("Smtp:User is not configured.");
        var password = configuration["Smtp:Password"]
            ?? throw new InvalidOperationException("Smtp:Password is not configured.");
        var from = configuration["Smtp:From"]
            ?? throw new InvalidOperationException("Smtp:From is not configured.");

        if (string.IsNullOrWhiteSpace(toEmail)
            || toEmail.Contains(',')
            || toEmail.Contains(';')
            || toEmail.Contains('\r')
            || toEmail.Contains('\n')
            || !MailAddress.TryCreate(toEmail, out var recipient)
            || !string.Equals(recipient.Address, toEmail.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException("Invalid recipient email address.", nameof(toEmail));
        }

        var port = 587;
        if (int.TryParse(configuration["Smtp:Port"], out var parsedPort) && parsedPort > 0)
            port = parsedPort;

        var timeoutMs = (int)DefaultTimeout.TotalMilliseconds;
        if (int.TryParse(configuration["Smtp:TimeoutMs"], out var parsedTimeout) && parsedTimeout > 0)
            timeoutMs = parsedTimeout;

        // Mailgun on 587 uses STARTTLS → EnableSsl = true.
        var enableSsl = !string.Equals(
            configuration["Smtp:EnableSsl"],
            "false",
            StringComparison.OrdinalIgnoreCase);

        using var message = new MailMessage
        {
            From = new MailAddress(from),
            Subject = subject,
            SubjectEncoding = Encoding.UTF8,
            BodyEncoding = Encoding.UTF8,
        };
        message.To.Add(recipient);

        // multipart/alternative: plain first, HTML last. Do not also set Body —
        // that duplicates content and breaks clients (Android double body, raw HTML in webmail).
        var plain = AlternateView.CreateAlternateViewFromString(
            textBody,
            Encoding.UTF8,
            MediaTypeNames.Text.Plain);
        var html = AlternateView.CreateAlternateViewFromString(
            htmlBody,
            Encoding.UTF8,
            MediaTypeNames.Text.Html);
        message.AlternateViews.Add(plain);
        message.AlternateViews.Add(html);

        using var client = new SmtpClient(host, port)
        {
            EnableSsl = enableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network,
            UseDefaultCredentials = false,
            Credentials = new NetworkCredential(user, password),
            Timeout = timeoutMs,
        };

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(timeoutMs);

        try
        {
            await client.SendMailAsync(message, timeoutCts.Token);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "SMTP send failed to {To}", recipient.Address);
            throw new InvalidOperationException("Nie udało się wysłać wiadomości e-mail.", ex);
        }
    }
}
