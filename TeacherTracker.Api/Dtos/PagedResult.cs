namespace TeacherTracker.Api.Dtos;

/// A page of results plus the total row count, for offset-paginated admin lists
/// (the app's user-facing lists use cursor paging; admin tables need page numbers).
public record PagedResult<T>(
    IReadOnlyList<T> Items,
    int Total,
    int Page,
    int PageSize);
