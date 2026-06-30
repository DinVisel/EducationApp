using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// AppDbContext'i sisteme ve PostgreSQL'e bağlıyoruz
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

app.MapGet("/", () => "Teacher Tracker API Çalışıyor!");

app.Run();