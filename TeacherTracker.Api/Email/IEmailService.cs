namespace TeacherTracker.Api.Email;

/// Sends transactional emails (e.g. password reset codes). See
/// <see cref="ConsoleEmailService"/> for the current dev-only implementation.
public interface IEmailService
{
    Task SendAsync(string toEmail, string subject, string bodyText, CancellationToken ct = default);
}
