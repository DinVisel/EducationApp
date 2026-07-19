using System.Security.Cryptography;

namespace TeacherTracker.Api.Auth;

/// Generates the short, human-friendly codes used by the hybrid onboarding
/// flows: per-student Access Codes (Method A) and per-class Class Codes
/// (Method B), plus the long random secret behind an access-card QR.
///
/// Codes are drawn from an unambiguous alphabet (no 0/O, 1/I/L) so a child can
/// read one off a printed card without confusion. They are deliberately short
/// and therefore low-entropy — callers MUST pair them with rate limiting and
/// uniqueness checks; the QR token is the high-entropy path.
public static class CodeGenerator
{
    private const string Alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"; // 31 symbols

    /// A short access/class code, default 6 chars ≈ 31^6 ≈ 8.9e8 combinations.
    public static string ShortCode(int length = 6)
    {
        Span<char> buffer = stackalloc char[length];
        for (var i = 0; i < length; i++)
            buffer[i] = Alphabet[RandomNumberGenerator.GetInt32(Alphabet.Length)];
        return new string(buffer);
    }

    /// A long, high-entropy secret (256-bit) encoded behind an access-card QR.
    /// The raw value is handed out once; only its SHA-256 hash is stored.
    public static string QrSecret() =>
        Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
}
