using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;
using TeacherTracker.Api.Storage;

namespace TeacherTracker.Api.Controllers;

/// Brokers uploads/downloads to Cloudflare R2. Phase 0 uses a server-side proxy
/// upload (client → API → R2) to avoid R2 CORS setup; large-file direct
/// (presigned PUT) uploads land in Phase 6.
[ApiController]
[Authorize]
[Route("api/[controller]")]
public class FilesController : ControllerBase
{
    // Reject uploads larger than this to protect the proxy path.
    private const long MaxUploadBytes = 25 * 1024 * 1024; // 25 MB

    private readonly AppDbContext _db;
    private readonly IFileStorage _storage;

    public FilesController(AppDbContext db, IFileStorage storage)
    {
        _db = db;
        _storage = storage;
    }

    private int UserId => User.GetUserId();

    [HttpPost]
    [RequestSizeLimit(MaxUploadBytes)]
    public async Task<ActionResult<FileObjectDto>> Upload(IFormFile file, CancellationToken ct)
    {
        if (file is null || file.Length == 0)
            return BadRequest("No file provided.");
        if (file.Length > MaxUploadBytes)
            return BadRequest("File exceeds the maximum upload size.");

        var contentType = string.IsNullOrWhiteSpace(file.ContentType)
            ? "application/octet-stream"
            : file.ContentType;
        var key = $"uploads/{UserId}/{Guid.NewGuid():N}{Path.GetExtension(file.FileName)}";

        await using var stream = file.OpenReadStream();
        var size = await _storage.PutAsync(stream, key, contentType, ct);

        var record = new FileObject
        {
            Key = key,
            FileName = file.FileName,
            ContentType = contentType,
            Size = size,
            OwnerUserId = UserId,
        };
        _db.Files.Add(record);
        await _db.SaveChangesAsync(ct);

        return Ok(ToDto(record));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<FileUrlDto>> GetUrl(int id)
    {
        var file = await _db.Files
            .AsNoTracking()
            .FirstOrDefaultAsync(f => f.Id == id);
        if (file is null)
            return NotFound();

        // The owner can always fetch it. A student may fetch a file only if it's
        // attached to an assignment that was fanned out to them.
        if (file.OwnerUserId != UserId && !await CanStudentAccessAsync(id))
            return NotFound();

        return Ok(new FileUrlDto(_storage.GetPresignedGetUrl(file.Key)));
    }

    // True when the caller is a student assigned an assignment carrying this file.
    private async Task<bool> CanStudentAccessAsync(int fileId)
    {
        if (User.GetRole() != UserRole.Student)
            return false;

        var studentId = User.GetStudentId();
        return await _db.AssignmentAttachments.AnyAsync(a =>
            a.FileObjectId == fileId &&
            a.Assignment!.StudentAssignments.Any(sa => sa.StudentId == studentId));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var file = await _db.Files
            .FirstOrDefaultAsync(f => f.Id == id && f.OwnerUserId == UserId);
        if (file is null)
            return NotFound();

        await _storage.DeleteAsync(file.Key, ct);
        _db.Files.Remove(file);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }

    private static FileObjectDto ToDto(FileObject f) =>
        new(f.Id, f.FileName, f.ContentType, f.Size, f.CreatedAt);
}
