using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Dtos;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Controllers;

[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/students/{studentId:int}/books")]
public class BooksController : StudentScopedController
{
    public BooksController(AppDbContext db) : base(db) { }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<BookDto>>> GetAll(
        int studentId, [FromQuery] int? beforeId, [FromQuery] int limit = 20)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var take = Math.Clamp(limit, 1, 50);

        var books = await Db.Books
            .AsNoTracking()
            .Where(b => b.StudentId == studentId)
            .Where(b => beforeId == null || b.Id < beforeId)
            .OrderByDescending(b => b.Id)
            .Take(take)
            .Select(b => ToDto(b))
            .ToListAsync();

        return Ok(books);
    }

    [HttpPost]
    public async Task<ActionResult<BookDto>> Create(int studentId, CreateBookDto dto)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var book = new Book
        {
            StudentId = studentId,
            Title = dto.Title,
            Author = dto.Author,
            Status = dto.Status,
            Rating = dto.Rating,
            CreatedAt = DateTime.UtcNow
        };

        Db.Books.Add(book);
        await Db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAll), new { studentId }, ToDto(book));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int studentId, int id, UpdateBookDto dto)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var book = await Db.Books
            .FirstOrDefaultAsync(b => b.Id == id && b.StudentId == studentId);
        if (book is null)
            return NotFound();

        book.Title = dto.Title;
        book.Author = dto.Author;
        book.Status = dto.Status;
        book.Rating = dto.Rating;
        await Db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int studentId, int id)
    {
        if (!await OwnsStudentAsync(studentId))
            return NotFound();

        var book = await Db.Books
            .FirstOrDefaultAsync(b => b.Id == id && b.StudentId == studentId);
        if (book is null)
            return NotFound();

        Db.Books.Remove(book);
        await Db.SaveChangesAsync();
        return NoContent();
    }

    private static BookDto ToDto(Book b) =>
        new(b.Id, b.Title, b.Author, b.Status, b.Rating, b.CreatedAt, b.StudentId);
}
