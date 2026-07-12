using System.Globalization;
using System.Text;
using Microsoft.Extensions.Options;

namespace TeacherTracker.Api.Moderation;

/// Detects profane / sensitive terms in free text. Normalizes input first
/// (lowercase, strip diacritics, fold common leet substitutions, collapse
/// separators) so trivial evasions like "f.u.c.k" or "s3x" are still caught.
/// Matching is whole-word on the normalized, separator-stripped form.
public class ProfanityGuard
{
    // Bundled defaults (English + Turkish). Kept intentionally small and blunt;
    // deployments extend via `Moderation:BlockedTerms`.
    private static readonly string[] DefaultTerms =
    {
        // English
        "fuck", "shit", "bitch", "asshole", "bastard", "cunt", "dick", "pussy",
        "nigger", "faggot", "whore", "slut", "rape",
        // Turkish
        "amk", "aq", "orospu", "pic", "piç", "gavat", "yavsak", "yavşak",
        "sikeyim", "siktir", "amcik", "amcık", "gerizekali", "gerizekalı",
        "salak", "aptal", "pezevenk",
    };

    private readonly HashSet<string> _terms;

    public ProfanityGuard(IOptions<ModerationOptions> options)
    {
        var opts = options.Value;
        _terms = new HashSet<string>(StringComparer.Ordinal);
        foreach (var t in DefaultTerms.Concat(opts.BlockedTerms))
        {
            var normalized = Normalize(t).Replace(" ", string.Empty);
            if (normalized.Length > 0)
                _terms.Add(normalized);
        }
    }

    /// True when [text] contains a blocked term. Returns the matched term via
    /// [match] for logging/messaging.
    public bool Contains(string? text, out string? match)
    {
        match = null;
        if (string.IsNullOrWhiteSpace(text))
            return false;

        var normalized = Normalize(text);
        // Whole-word check on the token stream…
        var tokens = normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        foreach (var token in tokens)
        {
            if (_terms.Contains(token))
            {
                match = token;
                return true;
            }
        }

        // …plus a separator-stripped substring check to catch "f u c k" / "f-u-c-k".
        var collapsed = normalized.Replace(" ", string.Empty);
        foreach (var term in _terms)
        {
            if (collapsed.Contains(term, StringComparison.Ordinal))
            {
                match = term;
                return true;
            }
        }

        return false;
    }

    // Lowercase, strip diacritics, map leet chars to letters, and reduce every
    // non-alphanumeric run to a single space.
    private static string Normalize(string input)
    {
        var lowered = input.ToLowerInvariant();

        // Decompose accents (ş→s, ç→c, é→e …) then drop the combining marks.
        var decomposed = lowered.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder(decomposed.Length);
        foreach (var ch in decomposed)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(ch) == UnicodeCategory.NonSpacingMark)
                continue;
            sb.Append(MapLeet(ch));
        }

        // Collapse anything that isn't a-z/0-9 into single spaces.
        var folded = sb.ToString();
        var result = new StringBuilder(folded.Length);
        var lastWasSpace = false;
        foreach (var ch in folded)
        {
            if ((ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9'))
            {
                result.Append(ch);
                lastWasSpace = false;
            }
            else if (!lastWasSpace)
            {
                result.Append(' ');
                lastWasSpace = true;
            }
        }

        return result.ToString().Trim();
    }

    private static char MapLeet(char ch) => ch switch
    {
        '0' => 'o',
        '1' => 'i',
        '3' => 'e',
        '4' => 'a',
        '5' => 's',
        '7' => 't',
        '@' => 'a',
        '$' => 's',
        _ => ch,
    };
}
