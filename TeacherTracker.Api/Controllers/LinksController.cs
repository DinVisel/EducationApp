using System.Text;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using TeacherTracker.Api.Data;
using TeacherTracker.Api.Links;

namespace TeacherTracker.Api.Controllers;

/// Public (unauthenticated) endpoints backing shareable post links: the iOS /
/// Android association files the OS fetches to verify Universal/App Links, and an
/// HTML fallback page shown to recipients who don't have the app installed.
[ApiController]
[AllowAnonymous]
public class LinksController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly DeepLinkOptions _options;

    public LinksController(AppDbContext db, IOptions<DeepLinkOptions> options)
    {
        _db = db;
        _options = options.Value;
    }

    // iOS Universal Links: the OS fetches this to learn which paths open the app.
    // Must be served as application/json over HTTPS with no redirect.
    [HttpGet("/.well-known/apple-app-site-association")]
    public ContentResult AppleAppSiteAssociation()
    {
        var appId = $"{_options.IosTeamId}.{_options.IosBundleId}";
        var json = $$"""
        {
          "applinks": {
            "apps": [],
            "details": [
              { "appID": "{{appId}}", "paths": ["/post/*"] }
            ]
          }
        }
        """;
        return Content(json, "application/json", Encoding.UTF8);
    }

    // Android App Links: the OS fetches this to verify the app owns this domain.
    [HttpGet("/.well-known/assetlinks.json")]
    public ContentResult AssetLinks()
    {
        var fingerprints = string.Join(",\n            ",
            _options.AndroidSha256CertFingerprints.Select(f => $"\"{f}\""));
        var json = $$"""
        [
          {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
              "namespace": "android_app",
              "package_name": "{{_options.AndroidPackageName}}",
              "sha256_cert_fingerprints": [
            {{fingerprints}}
              ]
            }
          }
        ]
        """;
        return Content(json, "application/json", Encoding.UTF8);
    }

    // The web fallback for a shared post. If the app is installed the OS opens it
    // directly and never loads this page; otherwise the recipient lands here and is
    // sent to the right store (with a manual "open in app" attempt via the scheme).
    [HttpGet("/post/{id:int}")]
    public async Task<ContentResult> PostFallback(int id)
    {
        var post = await _db.Posts
            .AsNoTracking()
            .Where(p => p.Id == id)
            .Select(p => new
            {
                p.Text,
                Author = p.Author!.Teacher!.FirstName + " " + p.Author.Teacher.LastName,
            })
            .FirstOrDefaultAsync();

        var enc = HtmlEncoder.Default;
        var title = post is null ? "Shared post" : $"{enc.Encode(post.Author)} shared a post";
        var description = post is null
            ? "Open this post in the app."
            : enc.Encode(Truncate(post.Text, 160));
        var appLink = $"{_options.AppScheme}://post/{id}";
        var jsAppStore = enc.Encode(_options.AppStoreUrl);
        var jsPlayStore = enc.Encode(_options.PlayStoreUrl);

        var html = $$"""
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>{{title}}</title>
          <meta property="og:title" content="{{title}}" />
          <meta property="og:description" content="{{description}}" />
          <meta property="og:type" content="article" />
        </head>
        <body style="font-family:-apple-system,system-ui,sans-serif;text-align:center;padding:48px 24px;">
          <h1>{{title}}</h1>
          <p>{{description}}</p>
          <p><a id="openApp" href="{{appLink}}">Open in the app</a></p>
          <p><a id="store" href="#">Get the app</a></p>
          <script>
            var appStore = "{{jsAppStore}}";
            var playStore = "{{jsPlayStore}}";
            var ua = navigator.userAgent || "";
            var isIOS = /iPad|iPhone|iPod/.test(ua);
            var storeUrl = isIOS ? appStore : playStore;
            document.getElementById("store").href = storeUrl || "#";
            // Try the app; if it doesn't take over, fall back to the store.
            var now = Date.now();
            window.location = "{{appLink}}";
            setTimeout(function () {
              if (Date.now() - now < 2000 && storeUrl) window.location = storeUrl;
            }, 1200);
          </script>
        </body>
        </html>
        """;
        return Content(html, "text/html", Encoding.UTF8);
    }

    private static string Truncate(string s, int max) =>
        string.IsNullOrEmpty(s) || s.Length <= max ? s : s[..max] + "…";
}
