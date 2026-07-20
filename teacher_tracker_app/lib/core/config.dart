import 'package:flutter/foundation.dart';

/// Base URL of the TeacherTracker .NET API.
///
/// The Android emulator can't reach the host's `localhost`; it maps the host
/// machine to `10.0.2.2`. Every other target (web, iOS simulator, desktop) can
/// use `localhost` directly. Swap these for a real host when deploying.
String get apiBaseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5001';
  }
  return 'http://localhost:5001';
}

/// Google OAuth client IDs for social sign-in (fill from Google Cloud Console).
///
/// [googleServerClientId] is the **Web** client ID; google_sign_in mints the ID
/// token with this as its audience, so it must be listed in the API's
/// `SocialAuth:Google:ClientIds`. [googleIosClientId] is the **iOS** client ID
/// (leave empty on Android — it uses the bundled google-services config).
///
/// Pass at build time, e.g.
/// `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=... --dart-define=GOOGLE_IOS_CLIENT_ID=...`.
const String googleServerClientId =
    String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const String googleIosClientId =
    String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// Public HTTPS host that shareable post links point at, e.g.
/// `https://app.example.com/post/42`. This must match the domain configured for
/// iOS Universal Links / Android App Links and the API's `DeepLink:PublicWebBaseUrl`.
/// Swap for your real domain when deploying.
const String publicWebBaseUrl = 'https://app.example.com';

/// Privacy policy shown at the mandatory profile-setup gate (KVKK/GDPR notice
/// for the demographic data we collect). Swap for your real policy URL.
const String privacyPolicyUrl = '$publicWebBaseUrl/privacy';
