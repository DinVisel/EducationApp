using System.Text;
using Amazon.S3;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
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

// Allow the Flutter client to call the API during development.
const string FlutterCorsPolicy = "FlutterClient";
builder.Services.AddCors(options =>
{
    options.AddPolicy(FlutterCorsPolicy, policy =>
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(); // UI available at /scalar/v1
}

app.UseCors(FlutterCorsPolicy);

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => "Teacher Tracker API Çalışıyor!");
app.MapControllers();

app.Run();
