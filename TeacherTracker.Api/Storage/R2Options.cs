namespace TeacherTracker.Api.Storage;

/// Cloudflare R2 connection settings. R2 is S3-compatible, so we talk to it with
/// AWSSDK.S3 pointed at the R2 endpoint. Real credentials belong in
/// `dotnet user-secrets` / environment variables — never in appsettings.json.
public class R2Options
{
    public const string SectionName = "R2";

    /// S3 API endpoint, e.g. https://<accountid>.r2.cloudflarestorage.com
    public string Endpoint { get; set; } = string.Empty;
    public string AccessKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string Bucket { get; set; } = string.Empty;

    /// How long presigned download URLs stay valid.
    public int PresignedUrlMinutes { get; set; } = 15;
}
