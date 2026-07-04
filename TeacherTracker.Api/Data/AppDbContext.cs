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
    public DbSet<Classroom> Classrooms { get; set; }
    public DbSet<Enrollment> Enrollments { get; set; }
    public DbSet<Assignment> Assignments { get; set; }
    public DbSet<AssignmentAttachment> AssignmentAttachments { get; set; }
    public DbSet<StudentAssignment> StudentAssignments { get; set; }

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

        // A teacher owns many classrooms; deleting the teacher removes them.
        modelBuilder.Entity<Classroom>()
            .HasOne(c => c.Teacher)
            .WithMany()
            .HasForeignKey(c => c.TeacherId)
            .OnDelete(DeleteBehavior.Cascade);

        // A student can only be enrolled in a given classroom once.
        modelBuilder.Entity<Enrollment>()
            .HasIndex(e => new { e.StudentId, e.ClassroomId })
            .IsUnique();

        // Removing either side removes the enrollment link.
        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.Classroom)
            .WithMany(c => c.Enrollments)
            .HasForeignKey(e => e.ClassroomId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Enrollment>()
            .HasOne(e => e.Student)
            .WithMany()
            .HasForeignKey(e => e.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting a classroom removes the assignments published to it.
        modelBuilder.Entity<Assignment>()
            .HasOne(a => a.Classroom)
            .WithMany()
            .HasForeignKey(a => a.ClassroomId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting a teacher removes the assignments they published (Postgres
        // allows this second cascade path alongside the classroom one).
        modelBuilder.Entity<Assignment>()
            .HasOne(a => a.Teacher)
            .WithMany()
            .HasForeignKey(a => a.TeacherId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting an assignment removes its attachment links (not the files).
        modelBuilder.Entity<AssignmentAttachment>()
            .HasOne(a => a.Assignment)
            .WithMany(a => a.Attachments)
            .HasForeignKey(a => a.AssignmentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the underlying file removes the attachment link too.
        modelBuilder.Entity<AssignmentAttachment>()
            .HasOne(a => a.FileObject)
            .WithMany()
            .HasForeignKey(a => a.FileObjectId)
            .OnDelete(DeleteBehavior.Cascade);

        // The same file can't be attached to one assignment twice.
        modelBuilder.Entity<AssignmentAttachment>()
            .HasIndex(a => new { a.AssignmentId, a.FileObjectId })
            .IsUnique();

        // Fan-out rows: deleting the assignment removes every student's copy.
        modelBuilder.Entity<StudentAssignment>()
            .HasOne(sa => sa.Assignment)
            .WithMany(a => a.StudentAssignments)
            .HasForeignKey(sa => sa.AssignmentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the student removes their assignment copies.
        modelBuilder.Entity<StudentAssignment>()
            .HasOne(sa => sa.Student)
            .WithMany()
            .HasForeignKey(sa => sa.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        // A student gets at most one copy of a given assignment.
        modelBuilder.Entity<StudentAssignment>()
            .HasIndex(sa => new { sa.AssignmentId, sa.StudentId })
            .IsUnique();
    }
}
