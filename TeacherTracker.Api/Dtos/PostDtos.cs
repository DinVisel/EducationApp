using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// A file attached to a post. `FileId` is used with `GET /api/files/{id}` to
/// obtain a presigned download URL.
public record PostAttachmentDto(
    int FileId,
    string FileName,
    string ContentType,
    long Size);

/// A post in the global teacher feed, with the caller's like state and counts.
/// `Subject` serializes as its enum name (JsonStringEnumConverter).
public record PostDto(
    int Id,
    int AuthorUserId,
    string AuthorName,
    int? AuthorAvatarFileId,
    PostSubject Subject,
    string Text,
    DateTime CreatedAt,
    int LikeCount,
    int CommentCount,
    bool LikedByMe,
    bool IsMine,
    bool IsPinned,
    IReadOnlyList<PostAttachmentDto> Attachments);

public record CreatePostDto(
    [Required, MaxLength(2000)] string Text,
    PostSubject Subject,
    // Ids of already-uploaded files (POST /api/files) to attach.
    IReadOnlyList<int>? FileIds);

/// A comment on a post; `IsMine` is true when the caller wrote it.
public record PostCommentDto(
    int Id,
    string AuthorName,
    string Text,
    DateTime CreatedAt,
    bool IsMine);

public record CreateCommentDto(
    [Required, MaxLength(1000)] string Text);
