import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import '../config.dart';

/// Called by the interceptor when the server rejects a *previously
/// authenticated* request (expired/invalid token) so the app can sign out.
final onUnauthorizedProvider = Provider<void Function()>((ref) => () {});

/// Shared, configured Dio instance for talking to the TeacherTracker API.
/// Attaches the bearer token when present and reacts to 401s.
final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStore.current;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) {
        // Only sign out when a request we authenticated gets rejected —
        // a 401 from login/register just means bad credentials.
        final wasAuthenticated =
            err.requestOptions.headers.containsKey('Authorization');
        if (err.response?.statusCode == 401 && wasAuthenticated) {
          ref.read(onUnauthorizedProvider)();
        }
        handler.next(err);
      },
    ),
  );

  return dio;
});
