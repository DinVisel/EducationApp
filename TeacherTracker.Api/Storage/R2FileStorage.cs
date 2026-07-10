using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Options;

namespace TeacherTracker.Api.Storage;

/// <see cref="IFileStorage"/> backed by Cloudflare R2 via the S3 SDK.
public class R2FileStorage : IFileStorage
{
    private readonly IAmazonS3 _s3;
    private readonly R2Options _options;

    public R2FileStorage(IAmazonS3 s3, IOptions<R2Options> options)
    {
        _s3 = s3;
        _options = options.Value;
    }

    public async Task<long> PutAsync(
        Stream content, string key, string contentType, CancellationToken ct = default)
    {
        // Buffer to a seekable stream so the SDK can set Content-Length; R2
        // rejects chunked/streaming uploads without a known length.
        var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, ct);
        buffer.Position = 0;

        await _s3.PutObjectAsync(new PutObjectRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            InputStream = buffer,
            ContentType = contentType,
            DisablePayloadSigning = true, // required for R2 compatibility
        }, ct);

        return buffer.Length;
    }

    public string GetPresignedGetUrl(string key) =>
        _s3.GetPreSignedURL(new GetPreSignedUrlRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.AddMinutes(_options.PresignedUrlMinutes),
        });

    public string GetPresignedPutUrl(string key, string contentType) =>
        _s3.GetPreSignedURL(new GetPreSignedUrlRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            Verb = HttpVerb.PUT,
            ContentType = contentType,
            Expires = DateTime.UtcNow.AddMinutes(_options.PresignedUrlMinutes),
        });

    public async Task<long?> GetSizeAsync(string key, CancellationToken ct = default)
    {
        try
        {
            var meta = await _s3.GetObjectMetadataAsync(new GetObjectMetadataRequest
            {
                BucketName = _options.Bucket,
                Key = key,
            }, ct);
            return meta.ContentLength;
        }
        catch (AmazonS3Exception e) when (e.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public Task DeleteAsync(string key, CancellationToken ct = default) =>
        _s3.DeleteObjectAsync(new DeleteObjectRequest
        {
            BucketName = _options.Bucket,
            Key = key,
        }, ct);
}
