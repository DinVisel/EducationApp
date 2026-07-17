namespace TeacherTracker.Api.Email;

/// Dev-only <see cref="IEmailService"/> that logs the message instead of
/// delivering it. No real SMTP/SendGrid/Mailgun provider is configured yet —
/// swap in a real implementation later by registering it in `Program.cs`.
public class ConsoleEmailService : IEmailService
{
    private readonly ILogger<ConsoleEmailService> _logger;

    public ConsoleEmailService(ILogger<ConsoleEmailService> logger)
    {
        _logger = logger;
    }

    public Task SendAsync(string toEmail, string subject, string bodyText, CancellationToken ct = default)
    {
        _logger.LogInformation(
            "Email (not sent, no provider configured) — To: {To}, Subject: {Subject}\n{Body}",
            toEmail, subject, bodyText);
        return Task.CompletedTask;
    }
}
