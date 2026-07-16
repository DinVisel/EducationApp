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

/// A preview of a quiz shared to the feed, shown on the post card. The full quiz
/// (for cloning) is fetched via `GET /api/quizzes/{QuizId}/preview`.
public record SharedQuizPreviewDto(
    int QuizId,
    string Title,
    QuizCategory Category,
    int QuestionCount);

/// A post in the global teacher feed, with the caller's like state and counts.
/// `Subject`/`GradeLevel` serialize as their enum names (JsonStringEnumConverter).
/// When `SharedQuiz` is set the post shares a quiz that teachers can rate 1–5
/// (`AverageRating`/`RatingCount`/`MyRating`) and clone.
public record PostDto(
    int Id,
    int AuthorUserId,
    string AuthorName,
    int? AuthorAvatarFileId,
    PostSubject Subject,
    GradeLevel? GradeLevel,
    string Text,
    DateTime CreatedAt,
    int LikeCount,
    int CommentCount,
    bool LikedByMe,
    bool IsMine,
    bool IsPinned,
    SharedQuizPreviewDto? SharedQuiz,
    double? AverageRating,
    int RatingCount,
    int? MyRating,
    IReadOnlyList<PostAttachmentDto> Attachments);

public record CreatePostDto(
    [Required, MaxLength(2000)] string Text,
    PostSubject Subject,
    GradeLevel? GradeLevel,
    // When set, shares this quiz (must be owned by the author) to the feed.
    int? SharedQuizId,
    // Ids of already-uploaded files (POST /api/files) to attach.
    IReadOnlyList<int>? FileIds);

/// A teacher's 1–5 star rating of a shared-quiz post.
public record RatePostDto(
    [Range(1, 5)] int Value);

/// A comment on a post; `IsMine` is true when the caller wrote it.
public record PostCommentDto(
    int Id,
    string AuthorName,
    string Text,
    DateTime CreatedAt,
    bool IsMine);

public record CreateCommentDto(
    [Required, MaxLength(1000)] string Text);
