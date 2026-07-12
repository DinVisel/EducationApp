using TeacherTracker.Api.Storage;

namespace TeacherTracker.Api.Tests;

/// In-memory <see cref="IFileStorage"/> so tests never touch R2. Tracks bytes by
/// key and returns fake presigned URLs.
public class FakeFileStorage : IFileStorage
{
    private readonly Dictionary<string, long> _sizes = new();

    public Task<long> PutAsync(
        Stream content, string key, string contentType, CancellationToken ct = default)
    {
        var size = content.CanSeek ? content.Length : 0;
        _sizes[key] = size;
        return Task.FromResult(size);
    }

    public string GetPresignedGetUrl(string key) => $"https://fake.local/{key}?get";

    public string GetPresignedPutUrl(string key, string contentType) =>
        $"https://fake.local/{key}?put";

    public Task<long?> GetSizeAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(_sizes.TryGetValue(key, out var s) ? s : (long?)null);

    public Task<Stream> GetObjectStreamAsync(string key, CancellationToken ct = default) =>
        // Byte content isn't tracked; return an empty stream (the fake image
        // moderator ignores content anyway).
        Task.FromResult<Stream>(new MemoryStream());

    public Task MoveAsync(string fromKey, string toKey, CancellationToken ct = default)
    {
        if (_sizes.TryGetValue(fromKey, out var size))
        {
            _sizes[toKey] = size;
            _sizes.Remove(fromKey);
        }
        return Task.CompletedTask;
    }

    /// Pretend an object of [size] bytes was uploaded at [key] (for confirm tests).
    public void Seed(string key, long size) => _sizes[key] = size;

    /// True when an object currently exists at [key] (for asserting deletes/moves).
    public bool Exists(string key) => _sizes.ContainsKey(key);

    public Task DeleteAsync(string key, CancellationToken ct = default)
    {
        _sizes.Remove(key);
        return Task.CompletedTask;
    }
}
