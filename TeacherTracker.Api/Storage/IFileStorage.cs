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

    /// Opens the object at <paramref name="key"/> for reading. Used to pull bytes
    /// back for content moderation before an upload is promoted to public.
    Task<Stream> GetObjectStreamAsync(string key, CancellationToken ct = default);

    /// Moves an object from one key to another (copy + delete — object stores have
    /// no native rename). Used to promote a scanned upload out of quarantine.
    Task MoveAsync(string fromKey, string toKey, CancellationToken ct = default);

    Task DeleteAsync(string key, CancellationToken ct = default);
}
