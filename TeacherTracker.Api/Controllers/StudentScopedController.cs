using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// Base for controllers nested under a student. Ensures the student belongs to
/// the authenticated teacher before any child record is read or written.
/// Teacher-only: derived controllers inherit this authorization.
[ApiController]
[Authorize(Roles = nameof(UserRole.Teacher))]
public abstract class StudentScopedController : ControllerBase
{
    protected readonly AppDbContext Db;

    protected StudentScopedController(AppDbContext db)
    {
        Db = db;
    }

    protected int TeacherId => User.GetTeacherId();

    protected Task<bool> OwnsStudentAsync(int studentId) =>
        Db.Students.AnyAsync(s => s.Id == studentId && s.TeacherId == TeacherId);
}
