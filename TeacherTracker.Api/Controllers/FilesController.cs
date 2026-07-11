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

    // --- Direct upload (presigned PUT): the client uploads straight to R2, then
    // confirms so we record the metadata. Preferred for large media. ---

    [HttpPost("presign")]
    public ActionResult<PresignUploadResponseDto> Presign(PresignUploadDto dto)
    {
        var contentType = string.IsNullOrWhiteSpace(dto.ContentType)
            ? "application/octet-stream"
            : dto.ContentType;
        var key = $"uploads/{UserId}/{Guid.NewGuid():N}{Path.GetExtension(dto.FileName)}";
        var url = _storage.GetPresignedPutUrl(key, contentType);
        return Ok(new PresignUploadResponseDto(url, key));
    }

    [HttpPost("confirm")]
    public async Task<ActionResult<FileObjectDto>> Confirm(ConfirmUploadDto dto, CancellationToken ct)
    {
        // The key must be one we issued to this caller (prevents claiming another
        // user's object or an arbitrary key).
        if (!dto.Key.StartsWith($"uploads/{UserId}/", StringComparison.Ordinal))
            return BadRequest("Invalid upload key.");

        var size = await _storage.GetSizeAsync(dto.Key, ct);
        if (size is null)
            return BadRequest("Upload not found — the file was not uploaded to R2.");
        if (size > MaxUploadBytes)
            return BadRequest("File exceeds the maximum upload size.");

        var contentType = string.IsNullOrWhiteSpace(dto.ContentType)
            ? "application/octet-stream"
            : dto.ContentType;

        var record = new FileObject
        {
            Key = dto.Key,
            FileName = dto.FileName,
            ContentType = contentType,
            Size = size.Value,
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

        // The owner can always fetch it. A student may fetch a file attached to an
        // assignment fanned out to them; any teacher may fetch a file attached to
        // a post in the global feed; any authenticated user may fetch a file used
        // as a teacher's profile picture / cover (needed to view profiles).
        if (file.OwnerUserId != UserId
            && !await CanStudentAccessAsync(id)
            && !await CanTeacherAccessPostFileAsync(id)
            && !await IsProfileImageAsync(id))
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

    // True when the caller is a teacher and the file is attached to any post in
    // the global feed (which every teacher can see).
    private async Task<bool> CanTeacherAccessPostFileAsync(int fileId)
    {
        if (User.GetRole() != UserRole.Teacher)
            return false;

        return await _db.PostAttachments.AnyAsync(a => a.FileObjectId == fileId);
    }

    // True when the file is a teacher's avatar or cover — profile images are
    // viewable by any authenticated user (profiles are cross-viewable).
    private Task<bool> IsProfileImageAsync(int fileId) =>
        _db.Teachers.AnyAsync(t =>
            t.AvatarFileObjectId == fileId || t.CoverFileObjectId == fileId);

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
