using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Email;
using TeacherTracker.Api.Moderation;
using TeacherTracker.Api.Storage;

namespace TeacherTracker.Api.Tests;

/// Boots the real API for integration tests, but backed by an in-memory SQLite
/// database and a fake file store so nothing touches Postgres or R2. Rate
/// limiting is disabled so the suite can register many accounts.
public class TestApiFactory : WebApplicationFactory<Program>
{
    private readonly SqliteConnection _connection = new("DataSource=:memory:");

    public FakeFileStorage Storage { get; } = new();

    public FakeImageModerator ImageModerator { get; } = new();

    public FakeEmailService EmailService { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        _connection.Open(); // keep the in-memory DB alive for the host lifetime

        builder.UseEnvironment("Development");

        // Override any developer user-secrets (Admin creds, R2 keys) so tests are
        // hermetic: no admin seeding at startup, and rate limiting off. Added last
        // so it wins over user-secrets/appsettings.
        builder.ConfigureAppConfiguration((_, cfg) =>
        {
            cfg.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["RateLimiting:Enabled"] = "false",
                ["Admin:Email"] = "",
                ["Admin:Password"] = "",
            });
        });

        builder.ConfigureServices(services =>
        {
            // Swap Npgsql for a shared in-memory SQLite connection. Remove every
            // DbContext-options registration (the concrete options plus EF's
            // internal options-configuration) so only SQLite is configured.
            var toRemove = services.Where(d =>
                d.ServiceType == typeof(DbContextOptions<AppDbContext>) ||
                d.ServiceType == typeof(DbContextOptions) ||
                (d.ServiceType.FullName?.Contains("IDbContextOptionsConfiguration") ?? false))
                .ToList();
            foreach (var d in toRemove) services.Remove(d);
            services.AddDbContext<AppDbContext>((sp, o) => o
                .UseSqlite(_connection)
                .AddInterceptors(sp.GetRequiredService<AuditInterceptor>()));

            // Swap R2 for the in-memory fake.
            services.RemoveAll<IFileStorage>();
            services.AddSingleton<IFileStorage>(Storage);

            // Swap the image moderator for a switchable fake (no AWS Rekognition).
            services.RemoveAll<IImageModerator>();
            services.AddSingleton<IImageModerator>(ImageModerator);

            // Swap email delivery for a fake that captures sent messages.
            services.RemoveAll<IEmailService>();
            services.AddSingleton<IEmailService>(EmailService);
        });
    }

    /// Creates the schema and returns a client. Call once per test.
    public HttpClient CreateApiClient()
    {
        var client = CreateClient();
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Database.EnsureCreated();
        return client;
    }

    /// Runs an action against the database (e.g. to seed an admin).
    public async Task WithDbAsync(Func<AppDbContext, Task> action)
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await action(db);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing) _connection.Dispose();
    }
}
