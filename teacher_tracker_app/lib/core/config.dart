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

/// Public HTTPS host that shareable post links point at, e.g.
/// `https://app.example.com/post/42`. This must match the domain configured for
/// iOS Universal Links / Android App Links and the API's `DeepLink:PublicWebBaseUrl`.
/// Swap for your real domain when deploying.
const String publicWebBaseUrl = 'https://app.example.com';
