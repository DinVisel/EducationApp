using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Teacher> Teachers { get; set; }
    public DbSet<Student> Students { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Email is the login identifier, so it must be unique.
        modelBuilder.Entity<Teacher>()
            .HasIndex(t => t.Email)
            .IsUnique();
    }
}