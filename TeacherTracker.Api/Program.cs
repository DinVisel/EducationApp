using Microsoft.EntityFrameworkCore;
using Scalar.AspNetCore;
using TeacherTracker.Api.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

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

app.MapGet("/", () => "Teacher Tracker API Çalışıyor!");
app.MapControllers();

app.Run();
