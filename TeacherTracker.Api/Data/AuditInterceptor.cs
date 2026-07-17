using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;
using TeacherTracker.Api.Auth;
using TeacherTracker.Api.Models;

namespace TeacherTracker.Api.Data;

/// Auto-populates CreatedBy/ModifiedAt/ModifiedBy on User/Post/Student rows from
/// the current authenticated request, so callers never have to set them by hand.
public class AuditInterceptor : SaveChangesInterceptor
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditInterceptor(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public override InterceptionResult<int> SavingChanges(
        DbContextEventData eventData, InterceptionResult<int> result)
    {
        Apply(eventData.Context);
        return base.SavingChanges(eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData, InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        Apply(eventData.Context);
        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    private void Apply(DbContext? context)
    {
        if (context is null) return;

        var userId = CurrentUserId();
        var now = DateTime.UtcNow;

        foreach (var entry in context.ChangeTracker.Entries())
        {
            if (entry.Entity is not (User or Post or Student)) continue;

            if (entry.State == EntityState.Added)
            {
                SetIfPresent(entry, "CreatedBy", userId);
            }
            else if (entry.State == EntityState.Modified)
            {
                SetIfPresent(entry, "ModifiedAt", now);
                SetIfPresent(entry, "ModifiedBy", userId);
            }
        }
    }

    private static void SetIfPresent(EntityEntry entry, string propertyName, object? value)
    {
        var property = entry.Properties.FirstOrDefault(p => p.Metadata.Name == propertyName);
        if (property is not null) property.CurrentValue = value;
    }

    private int? CurrentUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user?.Identity?.IsAuthenticated != true) return null;
        return user.GetUserId();
    }
}
