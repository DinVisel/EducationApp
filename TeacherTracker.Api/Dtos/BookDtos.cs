using System.ComponentModel.DataAnnotations;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Dtos;

public record BookDto(
    int Id,
    string Title,
    string? Author,
    BookStatus Status,
    int? Rating,
    DateTime CreatedAt,
    int StudentId);

public record CreateBookDto(
    [Required, MaxLength(200)] string Title,
    [MaxLength(150)] string? Author,
    BookStatus Status,
    [Range(1, 5)] int? Rating);

public record UpdateBookDto(
    [Required, MaxLength(200)] string Title,
    [MaxLength(150)] string? Author,
    BookStatus Status,
    [Range(1, 5)] int? Rating);
