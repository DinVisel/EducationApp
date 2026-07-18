using Serilog.Context;

namespace TeacherTracker.Api.Middleware;

/// Correlation ID: honours an inbound `X-Request-Id` (or mints a GUID), echoes it
/// back on the response, and pushes it onto Serilog's LogContext so every log line
/// emitted while handling the request carries a `RequestId` property for tracing.
public class RequestIdMiddleware
{
    public const string HeaderName = "X-Request-Id";

    private readonly RequestDelegate _next;

    public RequestIdMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = context.Request.Headers[HeaderName].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(requestId))
            requestId = Guid.NewGuid().ToString("N");

        context.Response.OnStarting(() =>
        {
            context.Response.Headers[HeaderName] = requestId;
            return Task.CompletedTask;
        });

        using (LogContext.PushProperty("RequestId", requestId))
        {
            await _next(context);
        }
    }
}
