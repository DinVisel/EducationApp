using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;

namespace TeacherTracker.Api.Caching;

/// Short-TTL in-memory cache for read-heavy, teacher-scoped responses, paired
/// with ETag/conditional-request support.
///
/// Cache keys always embed the owning teacher id (see the controllers), so one
/// teacher can never be served another teacher's cached payload. The cached
/// value carries a precomputed ETag; a matching <c>If-None-Match</c> short-
/// circuits to <c>304 Not Modified</c> so pollers skip re-transferring an
/// unchanged body.
///
/// This is a single-node cache. To cache across horizontally-scaled instances,
/// swap <see cref="IMemoryCache"/> for <c>IDistributedCache</c> (Redis) — the
/// key/ETag contract here stays the same.
public sealed class ApiResponseCache
{
    private readonly IMemoryCache _cache;

    public ApiResponseCache(IMemoryCache cache) => _cache = cache;

    public sealed record Entry(object Value, string ETag);

    /// Returns the cached entry for [key], or null on a miss.
    public Entry? Get(string key) => _cache.Get<Entry>(key);

    /// Caches [value] under [key] for [ttl], computing its ETag, and returns the
    /// stored entry so the caller can serve it immediately.
    public Entry Set(string key, object value, TimeSpan ttl)
    {
        var entry = new Entry(value, ComputeETag(value));
        _cache.Set(key, entry, ttl);
        return entry;
    }

    /// Drops a cached entry (call after a write that changes the resource).
    public void Remove(string key) => _cache.Remove(key);

    private static string ComputeETag(object value)
    {
        var json = JsonSerializer.SerializeToUtf8Bytes(value);
        var hash = SHA256.HashData(json);
        // Weak validator: the body is semantically, not byte-for-byte, equal.
        return $"W/\"{Convert.ToHexString(hash.AsSpan(0, 8))}\"";
    }
}

public static class CachedResponseExtensions
{
    /// Serves a cached [entry]: sets `ETag` + `Cache-Control`, returns
    /// `304 Not Modified` when the client's `If-None-Match` matches, otherwise
    /// `200 OK` with the value.
    public static ActionResult Cached(
        this ControllerBase controller, ApiResponseCache.Entry entry,
        int maxAgeSeconds = 30)
    {
        controller.Response.Headers.ETag = entry.ETag;
        controller.Response.Headers.CacheControl = $"private, max-age={maxAgeSeconds}";

        var ifNoneMatch = controller.Request.Headers.IfNoneMatch.ToString();
        if (!string.IsNullOrEmpty(ifNoneMatch) && ifNoneMatch == entry.ETag)
            return controller.StatusCode(StatusCodes.Status304NotModified);

        return controller.Ok(entry.Value);
    }
}
