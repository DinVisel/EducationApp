using TeacherTracker.Api.Email;

namespace TeacherTracker.Api.Tests;

/// A test <see cref="IEmailService"/> that captures sent messages instead of
/// delivering them, so tests can assert on password-reset tokens etc.
public class FakeEmailService : IEmailService
{
    public List<(string To, string Subject, string Body)> Sent { get; } = new();

    public Task SendAsync(string toEmail, string subject, string bodyText, CancellationToken ct = default)
    {
        Sent.Add((toEmail, subject, bodyText));
        return Task.CompletedTask;
    }
}
