namespace TeacherTracker.Api.Storage;

/// Abstraction over the object store (Cloudflare R2). Keeps controllers unaware
/// of the S3 SDK so the backing store can change without touching call sites.
public interface IFileStorage
{
    /// Uploads bytes under <paramref name="key"/> and returns the byte count.
    Task<long> PutAsync(
        Stream content, string key, string contentType, CancellationToken ct = default);

    /// A time-limited URL the client can GET directly from R2.
    string GetPresignedGetUrl(string key);

    Task DeleteAsync(string key, CancellationToken ct = default);
}
