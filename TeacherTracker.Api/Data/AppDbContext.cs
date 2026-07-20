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
    public DbSet<Post> Posts { get; set; }
    public DbSet<PostAttachment> PostAttachments { get; set; }
    public DbSet<PostLike> PostLikes { get; set; }
    public DbSet<PostComment> PostComments { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Report> Reports { get; set; }
    public DbSet<PostRating> PostRatings { get; set; }
    public DbSet<Quiz> Quizzes { get; set; }
    public DbSet<QuizQuestion> QuizQuestions { get; set; }
    public DbSet<QuizChoice> QuizChoices { get; set; }
    public DbSet<StudentQuizAttempt> StudentQuizAttempts { get; set; }
    public DbSet<StudentQuizAnswer> StudentQuizAnswers { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }
    public DbSet<Attendance> Attendances { get; set; }
    public DbSet<ClassJoinRequest> ClassJoinRequests { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Email is the login identifier, so it must be unique.
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();

        // A provider subject maps to at most one account. Both Postgres and SQLite
        // treat NULLs as distinct in a unique index, so the many accounts without
        // a given provider linked don't collide.
        modelBuilder.Entity<User>()
            .HasIndex(u => u.GoogleSubject)
            .IsUnique();
        modelBuilder.Entity<User>()
            .HasIndex(u => u.AppleSubject)
            .IsUnique();

        // Method A access-card credentials: each maps to at most one account, and
        // login is a direct lookup by them. NULLs are distinct (same as the social
        // subjects above), so all non-card accounts coexist without colliding.
        modelBuilder.Entity<User>()
            .HasIndex(u => u.AccessCode)
            .IsUnique();
        modelBuilder.Entity<User>()
            .HasIndex(u => u.AccessQrTokenHash)
            .IsUnique();

        // Store the role as readable text rather than an int.
        modelBuilder.Entity<User>()
            .Property(u => u.Role)
            .HasConversion<string>();

        // Soft delete: hide deleted rows from normal queries everywhere. Deletes
        // for these entities set IsDeleted rather than removing the row, so the
        // Cascade FK rules below never fire.
        modelBuilder.Entity<User>().HasQueryFilter(u => !u.IsDeleted);

        // 1:1 User → Teacher profile.
        modelBuilder.Entity<Teacher>()
            .HasOne(t => t.User)
            .WithOne(u => u.Teacher)
            .HasForeignKey<Teacher>(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Demographic enums as readable text rather than ints. City/District stay
        // free-text strings. Indexed for the admin GROUP BY aggregations.
        modelBuilder.Entity<Teacher>()
            .Property(t => t.SchoolType)
            .HasConversion<string>();
        modelBuilder.Entity<Teacher>()
            .Property(t => t.EducationLevel)
            .HasConversion<string>();
        modelBuilder.Entity<Teacher>()
            .HasIndex(t => t.City);
        modelBuilder.Entity<Teacher>()
            .HasIndex(t => new { t.City, t.District });

        // Optional profile picture / cover photo; clearing the file just nulls
        // the reference (keeps the teacher).
        modelBuilder.Entity<Teacher>()
            .HasOne(t => t.AvatarFileObject)
            .WithMany()
            .HasForeignKey(t => t.AvatarFileObjectId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<Teacher>()
            .HasOne(t => t.CoverFileObject)
            .WithMany()
            .HasForeignKey(t => t.CoverFileObjectId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<Student>().HasQueryFilter(s => !s.IsDeleted);

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

        // Perf: every Students/Classrooms read scopes by TeacherId.
        modelBuilder.Entity<Student>()
            .HasIndex(s => s.TeacherId);

        // Store the onboarding type as readable text rather than an int.
        modelBuilder.Entity<Student>()
            .Property(s => s.RegistrationType)
            .HasConversion<string>();

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

        // The global join code (Method B) must be unique so a lookup resolves to
        // exactly one class.
        modelBuilder.Entity<Classroom>()
            .HasIndex(c => c.ClassCode)
            .IsUnique();

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

        // --- Class join requests (Method B "Waiting Lobby") ---

        // Store the status as readable text rather than an int.
        modelBuilder.Entity<ClassJoinRequest>()
            .Property(r => r.Status)
            .HasConversion<string>();

        // Removing either side removes the request.
        modelBuilder.Entity<ClassJoinRequest>()
            .HasOne(r => r.Classroom)
            .WithMany()
            .HasForeignKey(r => r.ClassroomId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ClassJoinRequest>()
            .HasOne(r => r.Student)
            .WithMany()
            .HasForeignKey(r => r.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        // The lobby view lists a class's requests by status; the student's view
        // lists their own. Cover both. Uniqueness of a *live* request per
        // (student, class) is enforced in the controller so a rejected student can
        // re-request (a filtered unique index isn't portable across providers).
        modelBuilder.Entity<ClassJoinRequest>()
            .HasIndex(r => new { r.ClassroomId, r.Status });
        modelBuilder.Entity<ClassJoinRequest>()
            .HasIndex(r => r.StudentId);

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

        // Perf: teacher list = assignments for a classroom ordered by CreatedAt
        // desc; student list sorts by DueDate. Cover both.
        modelBuilder.Entity<Assignment>()
            .HasIndex(a => new { a.ClassroomId, a.CreatedAt });
        modelBuilder.Entity<Assignment>()
            .HasIndex(a => a.DueDate);

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

        // --- Social hub (global teacher feed) ---

        // Store the subject as readable text rather than an int.
        modelBuilder.Entity<Post>()
            .Property(p => p.Subject)
            .HasConversion<string>();

        modelBuilder.Entity<Post>().HasQueryFilter(p => !p.IsDeleted);

        // Deleting the author account removes their posts.
        modelBuilder.Entity<Post>()
            .HasOne(p => p.Author)
            .WithMany()
            .HasForeignKey(p => p.AuthorUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Perf: the feed filters by Subject and orders by Id desc; the profile
        // view filters by author and orders by Id desc. These composite indexes
        // cover both filter+sort patterns (GetFeed in PostsController).
        modelBuilder.Entity<Post>()
            .HasIndex(p => new { p.Subject, p.Id });
        modelBuilder.Entity<Post>()
            .HasIndex(p => new { p.AuthorUserId, p.Id });

        // Deleting a post removes its attachment links (not the files).
        modelBuilder.Entity<PostAttachment>()
            .HasOne(a => a.Post)
            .WithMany(p => p.Attachments)
            .HasForeignKey(a => a.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the underlying file removes the attachment link too.
        modelBuilder.Entity<PostAttachment>()
            .HasOne(a => a.FileObject)
            .WithMany()
            .HasForeignKey(a => a.FileObjectId)
            .OnDelete(DeleteBehavior.Cascade);

        // The same file can't be attached to one post twice.
        modelBuilder.Entity<PostAttachment>()
            .HasIndex(a => new { a.PostId, a.FileObjectId })
            .IsUnique();

        // Deleting a post removes its likes.
        modelBuilder.Entity<PostLike>()
            .HasOne(l => l.Post)
            .WithMany(p => p.Likes)
            .HasForeignKey(l => l.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the account removes their likes (second cascade path).
        modelBuilder.Entity<PostLike>()
            .HasOne(l => l.User)
            .WithMany()
            .HasForeignKey(l => l.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // A teacher likes a given post at most once.
        modelBuilder.Entity<PostLike>()
            .HasIndex(l => new { l.PostId, l.UserId })
            .IsUnique();

        // Deleting a post removes its comments.
        modelBuilder.Entity<PostComment>()
            .HasOne(c => c.Post)
            .WithMany(p => p.Comments)
            .HasForeignKey(c => c.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the author account removes their comments (second cascade path).
        modelBuilder.Entity<PostComment>()
            .HasOne(c => c.Author)
            .WithMany()
            .HasForeignKey(c => c.AuthorUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Store the grade as readable text rather than an int.
        modelBuilder.Entity<Post>()
            .Property(p => p.GradeLevel)
            .HasConversion<string>();

        // A post can share one quiz; deleting the quiz just clears the link so
        // the post (with its comments/ratings) survives as a historical record.
        modelBuilder.Entity<Post>()
            .HasOne(p => p.SharedQuiz)
            .WithMany()
            .HasForeignKey(p => p.SharedQuizId)
            .OnDelete(DeleteBehavior.SetNull);

        // Deleting a post removes its ratings.
        modelBuilder.Entity<PostRating>()
            .HasOne(r => r.Post)
            .WithMany(p => p.Ratings)
            .HasForeignKey(r => r.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the account removes their ratings (second cascade path).
        modelBuilder.Entity<PostRating>()
            .HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // A teacher rates a given post at most once (re-rating updates the row).
        modelBuilder.Entity<PostRating>()
            .HasIndex(r => new { r.PostId, r.UserId })
            .IsUnique();

        // --- Full-text search (Postgres only) ---
        // Generated tsvector columns + GIN indexes power the discovery search.
        // SQLite (tests) can't host tsvector, so the columns are ignored there
        // and SearchController falls back to LIKE.
        if (Database.IsNpgsql())
        {
            modelBuilder.Entity<Quiz>()
                .HasGeneratedTsVectorColumn(q => q.SearchVector, "english",
                    q => new { q.Title, q.Description })
                .HasIndex(q => q.SearchVector)
                .HasMethod("GIN");

            modelBuilder.Entity<FileObject>()
                .HasGeneratedTsVectorColumn(f => f.SearchVector, "english",
                    f => new { f.FileName })
                .HasIndex(f => f.SearchVector)
                .HasMethod("GIN");

            modelBuilder.Entity<Teacher>()
                .HasGeneratedTsVectorColumn(t => t.SearchVector, "english",
                    t => new { t.FirstName, t.LastName })
                .HasIndex(t => t.SearchVector)
                .HasMethod("GIN");
        }
        else
        {
            modelBuilder.Entity<Quiz>().Ignore(q => q.SearchVector);
            modelBuilder.Entity<FileObject>().Ignore(f => f.SearchVector);
            modelBuilder.Entity<Teacher>().Ignore(t => t.SearchVector);
        }

        // --- Notifications ---

        // Store the type as readable text rather than an int.
        modelBuilder.Entity<Notification>()
            .Property(n => n.Type)
            .HasConversion<string>();

        // Deleting the recipient account removes their notifications.
        modelBuilder.Entity<Notification>()
            .HasOne(n => n.Recipient)
            .WithMany()
            .HasForeignKey(n => n.RecipientUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Fetch a recipient's notifications newest-first.
        modelBuilder.Entity<Notification>()
            .HasIndex(n => new { n.RecipientUserId, n.CreatedAt });

        // --- Reports (moderation) ---

        // Store the resolution as readable text rather than an int.
        modelBuilder.Entity<Report>()
            .Property(r => r.Resolution)
            .HasConversion<string>();

        // Deleting the reporter account removes their reports.
        modelBuilder.Entity<Report>()
            .HasOne(r => r.Reporter)
            .WithMany()
            .HasForeignKey(r => r.ReporterUserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Removing reported content clears the link but keeps the report as a
        // historical record of the moderation action.
        modelBuilder.Entity<Report>()
            .HasOne(r => r.Post)
            .WithMany()
            .HasForeignKey(r => r.PostId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<Report>()
            .HasOne(r => r.PostComment)
            .WithMany()
            .HasForeignKey(r => r.PostCommentId)
            .OnDelete(DeleteBehavior.SetNull);

        // List open reports first.
        modelBuilder.Entity<Report>()
            .HasIndex(r => r.ResolvedAt);

        // --- Quizzes (teacher-authored, fanned out to a class) ---

        // Store the category as readable text rather than an int.
        modelBuilder.Entity<Quiz>()
            .Property(q => q.Category)
            .HasConversion<string>();

        // Deleting a classroom removes the quizzes published to it.
        modelBuilder.Entity<Quiz>()
            .HasOne(q => q.Classroom)
            .WithMany()
            .HasForeignKey(q => q.ClassroomId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting a teacher removes the quizzes they published (second cascade
        // path, as with Assignments).
        modelBuilder.Entity<Quiz>()
            .HasOne(q => q.Teacher)
            .WithMany()
            .HasForeignKey(q => q.TeacherId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting a quiz removes its questions.
        modelBuilder.Entity<QuizQuestion>()
            .HasOne(q => q.Quiz)
            .WithMany(z => z.Questions)
            .HasForeignKey(q => q.QuizId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting a question removes its choices.
        modelBuilder.Entity<QuizChoice>()
            .HasOne(c => c.Question)
            .WithMany(q => q.Choices)
            .HasForeignKey(c => c.QuestionId)
            .OnDelete(DeleteBehavior.Cascade);

        // Fan-out rows: deleting the quiz removes every student's attempt.
        modelBuilder.Entity<StudentQuizAttempt>()
            .HasOne(a => a.Quiz)
            .WithMany(q => q.Attempts)
            .HasForeignKey(a => a.QuizId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting the student removes their attempts.
        modelBuilder.Entity<StudentQuizAttempt>()
            .HasOne(a => a.Student)
            .WithMany()
            .HasForeignKey(a => a.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        // A student gets at most one attempt per quiz.
        modelBuilder.Entity<StudentQuizAttempt>()
            .HasIndex(a => new { a.QuizId, a.StudentId })
            .IsUnique();

        // Deleting an attempt removes its per-question answers.
        modelBuilder.Entity<StudentQuizAnswer>()
            .HasOne(a => a.Attempt)
            .WithMany(t => t.Answers)
            .HasForeignKey(a => a.AttemptId)
            .OnDelete(DeleteBehavior.Cascade);

        // --- Refresh tokens (session security) ---

        // Deleting the account removes its refresh tokens.
        modelBuilder.Entity<RefreshToken>()
            .HasOne(rt => rt.User)
            .WithMany()
            .HasForeignKey(rt => rt.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Refresh is a lookup by token hash, so index it.
        modelBuilder.Entity<RefreshToken>()
            .HasIndex(rt => rt.TokenHash);

        // --- Attendance ---

        // Store the status as readable text rather than an int.
        modelBuilder.Entity<Attendance>()
            .Property(a => a.Status)
            .HasConversion<string>();

        // Deleting a student removes their attendance records.
        modelBuilder.Entity<Attendance>()
            .HasOne(a => a.Student)
            .WithMany()
            .HasForeignKey(a => a.StudentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Deleting a classroom removes its attendance records (second cascade
        // path; Postgres allows this alongside the student one).
        modelBuilder.Entity<Attendance>()
            .HasOne(a => a.Classroom)
            .WithMany()
            .HasForeignKey(a => a.ClassroomId)
            .OnDelete(DeleteBehavior.Cascade);

        // The teacher who marked it; keep records if the FK is unset on delete.
        modelBuilder.Entity<Attendance>()
            .HasOne(a => a.Teacher)
            .WithMany()
            .HasForeignKey(a => a.TeacherId)
            .OnDelete(DeleteBehavior.Restrict);

        // One record per student per class per day (marking is an upsert).
        modelBuilder.Entity<Attendance>()
            .HasIndex(a => new { a.StudentId, a.ClassroomId, a.Date })
            .IsUnique();
    }
}
