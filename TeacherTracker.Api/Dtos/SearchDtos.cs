using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// A teacher match in global search (matched by name only).
public record TeacherResultDto(
    int UserId,
    string Name,
    int? AvatarFileId);

/// A discoverable material (a quiz or document shared to the feed). `PostId` is
/// the feed post to open; `QuizId` is set for quizzes (to clone/preview);
/// `FileId` is set for documents (to download).
public record MaterialResultDto(
    string Type, // "Quiz" | "Document"
    int PostId,
    string Title,
    PostSubject Subject,
    GradeLevel? GradeLevel,
    string AuthorName,
    int? QuizId,
    int? FileId);

/// Grouped results for the discovery search screen.
public record SearchResultsDto(
    IReadOnlyList<TeacherResultDto> Teachers,
    IReadOnlyList<MaterialResultDto> Materials);
