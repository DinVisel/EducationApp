namespace TeacherTracker.Api.Email;

/// Email delivery settings. No real provider is wired up yet — configure `Host`
/// (and the rest) here once a real SMTP/SendGrid/Mailgun account is available;
/// until then <see cref="ConsoleEmailService"/> logs messages instead of sending.
public class EmailOptions
{
    public const string SectionName = "Email";

    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string User { get; set; } = string.Empty;
    public string Pass { get; set; } = string.Empty;
    public string From { get; set; } = "no-reply@teachertracker.app";
}
