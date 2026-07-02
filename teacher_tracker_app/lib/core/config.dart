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
