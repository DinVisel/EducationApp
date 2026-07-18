using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

/// One student's status on a given day. `Status` is null when the student is on
/// the roster but hasn't been marked yet.
public record AttendanceStudentDto(
    int StudentId,
    string FirstName,
    string LastName,
    string StudentNumber,
    AttendanceStatus? Status,
    string? Note);

/// The whole class roster for one day, each student with their status (or
/// unmarked).
public record AttendanceDayDto(
    DateOnly Date,
    IReadOnlyList<AttendanceStudentDto> Students);

/// One entry in a bulk mark request.
public record AttendanceEntryDto(
    [Required] int StudentId,
    [Required] AttendanceStatus Status,
    [MaxLength(500)] string? Note = null);

/// Marks (upserts) attendance for a whole class on one day.
public record MarkAttendanceDto(
    [Required] DateOnly Date,
    [Required, MinLength(1)] List<AttendanceEntryDto> Entries);

/// A single historical record for a student.
public record AttendanceHistoryDto(
    int Id,
    DateOnly Date,
    AttendanceStatus Status,
    string? Note);

/// Per-student attendance totals + present rate across the class's history.
public record AttendanceSummaryDto(
    int StudentId,
    string FirstName,
    string LastName,
    int Present,
    int Absent,
    int Late,
    int Excused,
    int TotalDays,
    double AttendancePercent);
