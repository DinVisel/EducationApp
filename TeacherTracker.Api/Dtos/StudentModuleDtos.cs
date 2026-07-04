namespace TeacherTracker.Api.Dtos;

/// The signed-in student's own profile (their view of themselves).
public record StudentProfileDto(
    int Id,
    string FirstName,
    string LastName,
    string StudentNumber);

/// A class the student is enrolled in, with the teacher's name.
public record StudentClassDto(
    int Id,
    string Name,
    string TeacherName);

/// One of the student's assignments (their copy of a class assignment), with the
/// class context, the teacher's downloadable attachments, and their own status.
public record StudentAssignmentDto(
    int Id,
    int AssignmentId,
    string Title,
    string? Description,
    DateOnly? DueDate,
    string ClassName,
    bool IsDone,
    DateTime? CompletedAt,
    IReadOnlyList<AssignmentAttachmentDto> Attachments);
