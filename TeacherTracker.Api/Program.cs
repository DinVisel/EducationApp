using System.Text;
using System.Threading.RateLimiting;
using Amazon.Rekognition;
using Amazon.S3;
using Asp.Versioning;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using Serilog;
using Serilog.Formatting.Compact;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Caching;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Hubs;
using TeacherTracker.Api.Middleware;
using TeacherTracker.Api.Models;
using TeacherTracker.Api.Moderation;
using TeacherTracker.Api.Notifications;
using TeacherTracker.Api.Storage;
using TeacherTracker.Api.Email;

var builder = WebApplication.CreateBuilder(args);

// --- Structured logging (Serilog) ---
// Compact JSON to the console (production-friendly, machine-parseable); levels and
// overrides come from the "Serilog" configuration section. Enriched with the
// correlation id pushed by RequestIdMiddleware.
builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .WriteTo.Console(new CompactJsonFormatter()));

builder.Services.AddControllers()
    .AddJsonOptions(options =>
        // Serialize enums (e.g. BookStatus) as strings, not integers.
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()));
builder.Services.AddOpenApi();

// --- API versioning: every route is under /api/v{version}/... ---
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
}).AddMvc().AddApiExplorer(options =>
{
    options.GroupNameFormat = "'v'VVV";
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<AuditInterceptor>();

// --- Response caching ---
// Short-TTL in-memory cache + ETag support for read-heavy, teacher-scoped
// endpoints (classroom roster, quiz lists/analytics). See ApiResponseCache.
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<ApiResponseCache>();

// --- Health checks ---
// `/health` probes DB connectivity for load balancers / monitoring.
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>("db");

builder.Services.AddDbContext<AppDbContext>((sp, options) =>
    options
        .UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
        .AddInterceptors(sp.GetRequiredService<AuditInterceptor>()));

// --- Authentication (JWT) ---
builder.Services.Configure<JwtOptions>(
    builder.Configuration.GetSection(JwtOptions.SectionName));
builder.Services.AddScoped<TokenService>();

var jwt = builder.Configuration.GetSection(JwtOptions.SectionName).Get<JwtOptions>()
          ?? throw new InvalidOperationException("Missing 'Jwt' configuration section.");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
        };

        // WebSocket clients can't send an Authorization header, so SignalR passes
        // the JWT in the `access_token` query string. Only honour it for hub
        // paths, leaving normal API auth untouched.
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/hubs"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            },
        };
    });
builder.Services.AddAuthorization();

// --- Real-time notifications (SignalR) ---
builder.Services.AddSignalR();
builder.Services.AddScoped<INotificationPublisher, SignalRNotificationPublisher>();

// --- File storage (Cloudflare R2, S3-compatible) ---
builder.Services.Configure<R2Options>(
    builder.Configuration.GetSection(R2Options.SectionName));

var r2 = builder.Configuration.GetSection(R2Options.SectionName).Get<R2Options>()
         ?? new R2Options();

builder.Services.AddSingleton<IAmazonS3>(_ => new AmazonS3Client(
    new Amazon.Runtime.BasicAWSCredentials(r2.AccessKey, r2.SecretKey),
    new AmazonS3Config
    {
        ServiceURL = r2.Endpoint,
        ForcePathStyle = true, // R2 requires path-style addressing
        // R2 uses a single region alias.
        AuthenticationRegion = "auto",
    }));
builder.Services.AddScoped<IFileStorage, R2FileStorage>();

// --- Content moderation ---
builder.Services.Configure<ModerationOptions>(
    builder.Configuration.GetSection(ModerationOptions.SectionName));

var moderation = builder.Configuration.GetSection(ModerationOptions.SectionName)
    .Get<ModerationOptions>() ?? new ModerationOptions();

// Image moderation via AWS Rekognition (needs a real AWS account + region — the
// R2 alias won't authorize it). Falls back to a pass-through when disabled so the
// app runs without AWS credentials.
if (moderation.ImageModerationEnabled)
{
    builder.Services.AddSingleton<IAmazonRekognition>(_ => new AmazonRekognitionClient(
        new Amazon.Runtime.BasicAWSCredentials(moderation.AwsAccessKey, moderation.AwsSecretKey),
        new AmazonRekognitionConfig
        {
            RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(moderation.AwsRegion),
        }));
    builder.Services.AddScoped<IImageModerator, RekognitionImageModerator>();
}
else
{
    builder.Services.AddSingleton<IImageModerator, NullImageModerator>();
}

// Text moderation (profanity / sensitive keywords) applied per-action via the filter.
builder.Services.AddSingleton<ProfanityGuard>();
builder.Services.AddScoped<ProfanityFilterAttribute>();

// --- Email (password reset, etc.) ---
builder.Services.Configure<EmailOptions>(
    builder.Configuration.GetSection(EmailOptions.SectionName));
// No real provider is configured yet; logs the message instead of sending.
builder.Services.AddSingleton<IEmailService, ConsoleEmailService>();

// --- Deep linking (shareable post links) ---
builder.Services.Configure<TeacherTracker.Api.Links.DeepLinkOptions>(
    builder.Configuration.GetSection(TeacherTracker.Api.Links.DeepLinkOptions.SectionName));

// CORS: lock down to configured origins in production; permissive in dev when
// none are configured. Set `Cors:AllowedOrigins` (array) for deployment.
const string FlutterCorsPolicy = "FlutterClient";
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy(FlutterCorsPolicy, policy =>
    {
        if (allowedOrigins.Length == 0)
            policy.AllowAnyOrigin();
        else
            policy.WithOrigins(allowedOrigins).AllowCredentials();
        policy.AllowAnyHeader().AllowAnyMethod();
    });
});

// Rate limiting: a global per-IP cap plus a stricter policy for auth endpoints
// (brute-force protection). Rejections return 429. Toggleable so tests (and
// trusted internal deployments) can disable it via `RateLimiting:Enabled`.
var rateLimitingEnabled =
    builder.Configuration.GetValue("RateLimiting:Enabled", true);
if (rateLimitingEnabled)
    builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(ctx =>
        RateLimitPartition.GetFixedWindowLimiter(
            ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 300,
                Window = TimeSpan.FromMinutes(1),
            }));

    options.AddFixedWindowLimiter("auth", opt =>
    {
        opt.PermitLimit = 10;
        opt.Window = TimeSpan.FromMinutes(1);
    });

    // Per-user caps on write-heavy endpoints (partitioned by the JWT `sub` claim,
    // falling back to IP for the rare unauthenticated hit). These sit *under* the
    // global per-IP cap and curb storage-exhaustion / spam from a single account.
    static string UserPartition(HttpContext ctx) =>
        ctx.User.FindFirst("sub")?.Value
        ?? ctx.Connection.RemoteIpAddress?.ToString()
        ?? "unknown";

    options.AddPolicy("uploads", ctx =>
        RateLimitPartition.GetFixedWindowLimiter(UserPartition(ctx),
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 30,
                Window = TimeSpan.FromMinutes(1),
            }));

    options.AddPolicy("writes", ctx =>
        RateLimitPartition.GetFixedWindowLimiter(UserPartition(ctx),
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 60,
                Window = TimeSpan.FromMinutes(1),
            }));
});

var app = builder.Build();

// Correlation id first so every downstream log line (including request logging)
// carries it.
app.UseMiddleware<RequestIdMiddleware>();
app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(); // UI available at /scalar/v1
}

app.UseCors(FlutterCorsPolicy);

if (rateLimitingEnabled)
    app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => "Teacher Tracker API Çalışıyor!");
app.MapHealthChecks("/health"); // load-balancer probe; unversioned + anonymous
app.MapControllers();
app.MapHub<NotificationsHub>("/hubs/notifications");

// In development, apply any pending EF migrations on startup so the schema stays
// in sync with the code without a manual `dotnet ef database update`. Left off
// outside development, where migrations should be applied deliberately as part
// of deployment.
if (app.Environment.IsDevelopment())
    await ApplyMigrationsAsync(app);

// Seed an admin account from configuration if one doesn't exist yet. Set
// `Admin:Email` + `Admin:Password` (env/user-secrets) to bootstrap the first
// admin; leave unset to skip. Requires the schema to already be migrated.
await SeedAdminAsync(app);

app.Run();

static async Task ApplyMigrationsAsync(WebApplication app)
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    // Only the Postgres provider has these migrations; the integration tests run
    // on in-memory SQLite (via EnsureCreated) where MigrateAsync would fail.
    if (db.Database.IsNpgsql())
        await db.Database.MigrateAsync();
}

static async Task SeedAdminAsync(WebApplication app)
{
    var email = app.Configuration["Admin:Email"];
    var password = app.Configuration["Admin:Password"];
    if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        return;

    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var normalized = email.Trim().ToLowerInvariant();
    if (await db.Users.AnyAsync(u => u.Email == normalized))
        return;

    var admin = new User { Email = normalized, Role = UserRole.Admin };
    admin.PasswordHash = new PasswordHasher<User>().HashPassword(admin, password);
    db.Users.Add(admin);
    await db.SaveChangesAsync();
}

// Exposed so the integration test project can boot the app via WebApplicationFactory.
public partial class Program { }
