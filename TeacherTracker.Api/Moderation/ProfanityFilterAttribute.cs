using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;

namespace TeacherTracker.Api.Moderation;

/// Action filter that rejects a request whose body carries a blocked term in a
/// known free-text field. Short-circuits with 422 before the action runs, so no
/// profane content is ever persisted. Apply per-action via
/// `[ServiceFilter(typeof(ProfanityFilterAttribute))]` — never globally, so reads
/// and file uploads are untouched.
public class ProfanityFilterAttribute : Attribute, IAsyncActionFilter
{
    // Free-text properties we screen on incoming DTOs. Kept as a small allowlist so
    // opaque fields (keys, tokens, enums) are never matched by accident.
    private static readonly HashSet<string> ScreenedProperties =
        new(StringComparer.OrdinalIgnoreCase) { "Text", "Content", "Title", "Description" };

    private readonly ProfanityGuard _guard;
    private readonly ModerationOptions _options;

    public ProfanityFilterAttribute(ProfanityGuard guard, IOptions<ModerationOptions> options)
    {
        _guard = guard;
        _options = options.Value;
    }

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (!_options.TextModerationEnabled)
        {
            await next();
            return;
        }

        foreach (var arg in context.ActionArguments.Values)
        {
            if (arg is null) continue;
            foreach (var prop in arg.GetType().GetProperties())
            {
                if (prop.PropertyType != typeof(string) ||
                    !ScreenedProperties.Contains(prop.Name))
                    continue;

                var value = prop.GetValue(arg) as string;
                if (_guard.Contains(value, out _))
                {
                    context.ModelState.AddModelError(
                        prop.Name, "Content contains language that isn't allowed.");
                    context.Result = new UnprocessableEntityObjectResult(context.ModelState);
                    return;
                }
            }
        }

        await next();
    }
}
