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

    /// A time-limited URL the client can PUT bytes to directly (with the given
    /// content type), bypassing the proxy upload for large media.
    string GetPresignedPutUrl(string key, string contentType);

    /// The size in bytes of the object at <paramref name="key"/>, or null when it
    /// doesn't exist. Used to confirm a direct upload actually landed.
    Task<long?> GetSizeAsync(string key, CancellationToken ct = default);

    Task DeleteAsync(string key, CancellationToken ct = default);
}
