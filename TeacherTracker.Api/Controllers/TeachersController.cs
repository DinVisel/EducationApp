using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// Read-only public profiles of other teachers, so the feed's author can be
/// tapped to view their profile (name, avatar, cover). Posts come from
/// `GET /api/posts?authorUserId=`.
[ApiController]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/teachers")]
public class TeachersController : ControllerBase
{
    private readonly AppDbContext _db;

    public TeachersController(AppDbContext db)
    {
        _db = db;
    }

    // Keyed by the teacher's *account* (User) id — the same id carried as a
    // post's AuthorUserId.
    [HttpGet("{userId:int}/profile")]
    public async Task<ActionResult<TeacherDto>> GetProfile(int userId)
    {
        var teacher = await _db.Teachers
            .AsNoTracking()
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.UserId == userId);
        if (teacher is null)
            return NotFound();

        return Ok(new TeacherDto(
            teacher.Id,
            teacher.UserId,
            teacher.FirstName,
            teacher.LastName,
            teacher.User!.Email,
            teacher.AvatarFileObjectId,
            teacher.CoverFileObjectId));
    }
}
