using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Teacher> Teachers { get; set; }
    public DbSet<Student> Students { get; set; }
    public DbSet<TrackingNote> TrackingNotes { get; set; }
    public DbSet<Homework> Homeworks { get; set; }
    public DbSet<Book> Books { get; set; }
    public DbSet<FileObject> Files { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Email is the login identifier, so it must be unique.
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // Store the role as readable text rather than an int.
        modelBuilder.Entity<User>()
            .Property(u => u.Role)
            .HasConversion<string>();

        // 1:1 User → Teacher profile.
        modelBuilder.Entity<Teacher>()
            .HasOne(t => t.User)
            .WithOne(u => u.Teacher)
            .HasForeignKey<Teacher>(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Optional 1:1 User → Student profile (student login, Phase 4).
        modelBuilder.Entity<Student>()
            .HasOne(s => s.User)
            .WithOne(u => u.Student)
            .HasForeignKey<Student>(s => s.UserId)
            .OnDelete(DeleteBehavior.SetNull);

        // Delete a student's child records along with the student.
        modelBuilder.Entity<Student>()
            .HasMany(s => s.TrackingNotes)
            .WithOne(n => n.Student!)
            .HasForeignKey(n => n.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Student>()
            .HasMany(s => s.Homeworks)
            .WithOne(h => h.Student!)
            .HasForeignKey(h => h.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Student>()
            .HasMany(s => s.Books)
            .WithOne(b => b.Student!)
            .HasForeignKey(b => b.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Store the enum as readable text rather than an int.
        modelBuilder.Entity<Book>()
            .Property(b => b.Status)
            .HasConversion<string>();
    }
}
