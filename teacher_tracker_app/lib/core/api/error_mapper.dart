import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';

/// Turns an arbitrary thrown [error] into a user-facing message, centralizing
/// the `DioException` handling that used to be copy-pasted into every screen.
///
/// Resolution order for a [DioException]:
///   1. A non-empty string body from the server (already human-readable).
///   2. A caller-supplied override for the response status code
///      (e.g. `{401: loc.loginInvalidCredentials}`).
///   3. [AppLocalizations.commonNetworkError] for connection/timeout failures
///      (no response), otherwise for any other Dio failure.
/// Anything that isn't a [DioException] falls back to
/// [AppLocalizations.commonSomethingWentWrong].
String messageForError(
  Object error,
  AppLocalizations loc, {
  Map<int, String>? statusMessages,
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is String && data.isNotEmpty) return data;

    final code = error.response?.statusCode;
    final override = code == null ? null : statusMessages?[code];
    if (override != null) return override;

    return loc.commonNetworkError;
  }
  return loc.commonSomethingWentWrong;
}
