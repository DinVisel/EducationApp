using System.Linq.Expressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

/// The global teacher social hub. Any teacher can publish a post (text + subject
/// + R2 attachments) to one shared feed and others can view, like, and comment.
/// Unlike assignments, the feed is not scoped to a single teacher's students.
[ApiController]
[Authorize(Roles = nameof(UserRole.Teacher))]
[Route("api/posts")]
public class PostsController : ControllerBase
{
    private readonly AppDbContext _db;

    public PostsController(AppDbContext db)
    {
        _db = db;
    }

    private int UserId => User.GetUserId();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<PostDto>>> GetFeed(
        [FromQuery] PostSubject? subject,
        [FromQuery] int? beforeId,
        [FromQuery] int limit = 20)
    {
        var take = Math.Clamp(limit, 1, 50);

        var posts = await _db.Posts
            .AsNoTracking()
            .Where(p => beforeId == null || p.Id < beforeId)
            .Where(p => subject == null || p.Subject == subject)
            .OrderByDescending(p => p.Id)
            .Take(take)
            .Select(Projection(UserId))
            .ToListAsync();

        return Ok(posts);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<PostDto>> GetById(int id)
    {
        var post = await _db.Posts
            .AsNoTracking()
            .Where(p => p.Id == id)
            .Select(Projection(UserId))
            .FirstOrDefaultAsync();

        return post is null ? NotFound() : Ok(post);
    }

    [HttpPost]
    public async Task<ActionResult<PostDto>> Create(CreatePostDto dto)
    {
        // Only attach files this teacher owns; silently drop anything else.
        var fileIds = (dto.FileIds ?? new List<int>()).Distinct().ToList();
        var ownedFileIds = fileIds.Count == 0
            ? new List<int>()
            : await _db.Files
                .Where(f => fileIds.Contains(f.Id) && f.OwnerUserId == UserId)
                .Select(f => f.Id)
                .ToListAsync();

        var post = new Post
        {
            AuthorUserId = UserId,
            Text = dto.Text.Trim(),
            Subject = dto.Subject,
            CreatedAt = DateTime.UtcNow,
            Attachments = ownedFileIds
                .Select(fid => new PostAttachment { FileObjectId = fid })
                .ToList(),
        };

        _db.Posts.Add(post);
        await _db.SaveChangesAsync();

        var created = await _db.Posts
            .AsNoTracking()
            .Where(p => p.Id == post.Id)
            .Select(Projection(UserId))
            .FirstAsync();

        return CreatedAtAction(nameof(GetById), new { id = post.Id }, created);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var post = await _db.Posts
            .FirstOrDefaultAsync(p => p.Id == id && p.AuthorUserId == UserId);
        if (post is null)
            return NotFound();

        _db.Posts.Remove(post);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{id:int}/like")]
    public async Task<IActionResult> Like(int id)
    {
        var authorUserId = await _db.Posts
            .Where(p => p.Id == id)
            .Select(p => (int?)p.AuthorUserId)
            .FirstOrDefaultAsync();
        if (authorUserId is null)
            return NotFound();

        // Idempotent: only insert if the teacher hasn't already liked it.
        var already = await _db.PostLikes
            .AnyAsync(l => l.PostId == id && l.UserId == UserId);
        if (!already)
        {
            _db.PostLikes.Add(new PostLike { PostId = id, UserId = UserId });
            // Notify the author of a new like (not when liking your own post).
            if (authorUserId != UserId)
                _db.Notifications.Add(new Notification
                {
                    RecipientUserId = authorUserId.Value,
                    Type = NotificationType.PostLiked,
                    Text = $"{User.GetName()} liked your post",
                    PostId = id,
                });
            await _db.SaveChangesAsync();
        }

        return NoContent();
    }

    [HttpDelete("{id:int}/like")]
    public async Task<IActionResult> Unlike(int id)
    {
        var like = await _db.PostLikes
            .FirstOrDefaultAsync(l => l.PostId == id && l.UserId == UserId);
        if (like is not null)
        {
            _db.PostLikes.Remove(like);
            await _db.SaveChangesAsync();
        }

        return NoContent();
    }

    [HttpGet("{id:int}/comments")]
    public async Task<ActionResult<IEnumerable<PostCommentDto>>> GetComments(int id)
    {
        if (!await _db.Posts.AnyAsync(p => p.Id == id))
            return NotFound();

        var comments = await _db.PostComments
            .AsNoTracking()
            .Where(c => c.PostId == id)
            .OrderBy(c => c.CreatedAt)
            .Select(c => new PostCommentDto(
                c.Id,
                c.Author!.Teacher!.FirstName + " " + c.Author.Teacher.LastName,
                c.Text,
                c.CreatedAt,
                c.AuthorUserId == UserId))
            .ToListAsync();

        return Ok(comments);
    }

    [HttpPost("{id:int}/comments")]
    public async Task<ActionResult<PostCommentDto>> AddComment(int id, CreateCommentDto dto)
    {
        var authorUserId = await _db.Posts
            .Where(p => p.Id == id)
            .Select(p => (int?)p.AuthorUserId)
            .FirstOrDefaultAsync();
        if (authorUserId is null)
            return NotFound();

        var comment = new PostComment
        {
            PostId = id,
            AuthorUserId = UserId,
            Text = dto.Text.Trim(),
            CreatedAt = DateTime.UtcNow,
        };
        _db.PostComments.Add(comment);
        // Notify the post author of a new comment (not on your own post).
        if (authorUserId != UserId)
            _db.Notifications.Add(new Notification
            {
                RecipientUserId = authorUserId.Value,
                Type = NotificationType.PostCommented,
                Text = $"{User.GetName()} commented on your post",
                PostId = id,
            });
        await _db.SaveChangesAsync();

        var created = await _db.PostComments
            .AsNoTracking()
            .Where(c => c.Id == comment.Id)
            .Select(c => new PostCommentDto(
                c.Id,
                c.Author!.Teacher!.FirstName + " " + c.Author.Teacher.LastName,
                c.Text,
                c.CreatedAt,
                c.AuthorUserId == UserId))
            .FirstAsync();

        return Ok(created);
    }

    [HttpDelete("{id:int}/comments/{commentId:int}")]
    public async Task<IActionResult> DeleteComment(int id, int commentId)
    {
        var comment = await _db.PostComments
            .FirstOrDefaultAsync(c =>
                c.Id == commentId && c.PostId == id && c.AuthorUserId == UserId);
        if (comment is null)
            return NotFound();

        _db.PostComments.Remove(comment);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    // Post → DTO with the caller's like state. Built per-request because
    // `LikedByMe` depends on the current user; kept as an Expression so EF
    // translates the counts and attachment join to SQL.
    private static Expression<Func<Post, PostDto>> Projection(int userId) => p =>
        new PostDto(
            p.Id,
            p.Author!.Teacher!.FirstName + " " + p.Author.Teacher.LastName,
            p.Subject,
            p.Text,
            p.CreatedAt,
            p.Likes.Count,
            p.Comments.Count,
            p.Likes.Any(l => l.UserId == userId),
            p.AuthorUserId == userId,
            p.Attachments
                .Select(at => new PostAttachmentDto(
                    at.FileObject!.Id,
                    at.FileObject.FileName,
                    at.FileObject.ContentType,
                    at.FileObject.Size))
                .ToList());
}
