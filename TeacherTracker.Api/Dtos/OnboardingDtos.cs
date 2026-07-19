using System.ComponentModel.DataAnnotations;

namespace TeacherTracker.Api.Dtos;

// ── Method A: Teacher-driven Access Card flow (ages 8-10) ───────────────────

/// A teacher bulk-provisions access-card students for a class by pasting a list
/// of names. Each name becomes a Student + passwordless login + enrollment.
public record CreateAccessCardsDto(
    [Required, MinLength(1)] List<string> Names);

/// One provisioned access card. <see cref="QrToken"/> is the raw QR secret,
/// returned ONLY at creation/rotation (never stored in plaintext, so it can't be
/// re-listed later — rotate to get a fresh one). It is null on the list endpoint.
public record AccessCardDto(
    int StudentId,
    string FirstName,
    string LastName,
    string AccessCode,
    string? QrToken = null);

/// Passwordless login with a typed access code (Method A).
public record AccessCodeLoginDto(
    [Required, MaxLength(32)] string Code);

/// Passwordless login by scanning an access-card QR (Method A).
public record AccessQrLoginDto(
    [Required, MaxLength(128)] string Token);

// ── Method B: Student-driven Class Code & Lobby flow (ages 11-16) ───────────

/// A self-registered student submits a class's global code to request to join.
public record JoinClassDto(
    [Required, MaxLength(32)] string ClassCode);

/// A join request as the student sees it (their own pending/decided requests).
public record ClassJoinRequestDto(
    int Id,
    int ClassroomId,
    string ClassName,
    string TeacherName,
    string Status,
    DateTime CreatedAt,
    DateTime? DecidedAt);

/// A pending join request as the teacher sees it in the class lobby.
public record LobbyEntryDto(
    int RequestId,
    int StudentId,
    string FirstName,
    string LastName,
    string? Email,
    DateTime CreatedAt);
