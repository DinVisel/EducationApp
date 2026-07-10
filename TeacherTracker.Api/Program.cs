using System.Text;
using System.Threading.RateLimiting;
using Amazon.S3;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Models;
using TeacherTracker.Api.Storage;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
        // Serialize enums (e.g. BookStatus) as strings, not integers.
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter()));
builder.Services.AddOpenApi();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

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
    });
builder.Services.AddAuthorization();

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
});

var app = builder.Build();

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
app.MapControllers();

// Seed an admin account from configuration if one doesn't exist yet. Set
// `Admin:Email` + `Admin:Password` (env/user-secrets) to bootstrap the first
// admin; leave unset to skip. Requires the schema to already be migrated.
await SeedAdminAsync(app);

app.Run();

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
