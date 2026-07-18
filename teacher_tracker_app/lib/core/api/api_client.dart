import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_store.dart';
import '../config.dart';

/// Called by the interceptor when the server rejects a *previously
/// authenticated* request and a token refresh could not recover it, so the app
/// can sign out.
final onUnauthorizedProvider = Provider<void Function()>((ref) => () {});

/// Shared, configured Dio instance for talking to the TeacherTracker API.
/// Attaches the bearer token, and on a 401 silently refreshes the access token
/// (single-flight) and retries before falling back to sign-out.
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

  // A bare client (no interceptors) for the refresh call itself, so refreshing
  // can't recurse through this interceptor or trigger a provider cycle.
  final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));

  // Single-flight guard: concurrent 401s share one in-flight refresh.
  Future<bool>? refreshing;

  Future<bool> runRefresh() async {
    final refreshToken = tokenStore.currentRefresh;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = res.data;
      final access = data?['token'] as String?;
      final newRefresh = data?['refreshToken'] as String?;
      if (access == null || newRefresh == null) return false;
      await tokenStore.saveTokens(access, newRefresh);
      return true;
    } on DioException {
      return false;
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStore.current;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        final request = err.requestOptions;
        // Only sign out / refresh when a request we authenticated gets rejected
        // — a 401 from login/register just means bad credentials.
        final wasAuthenticated = request.headers.containsKey('Authorization');
        final alreadyRetried = request.extra['__retried'] == true;

        if (err.response?.statusCode == 401 &&
            wasAuthenticated &&
            !alreadyRetried) {
          refreshing ??= runRefresh().whenComplete(() => refreshing = null);
          final ok = await refreshing!;

          if (ok) {
            // Replay the original request once with the new access token.
            final newToken = tokenStore.current;
            try {
              final response = await dio.request<dynamic>(
                request.path,
                data: request.data,
                queryParameters: request.queryParameters,
                cancelToken: request.cancelToken,
                options: Options(
                  method: request.method,
                  headers: {
                    ...request.headers,
                    'Authorization': 'Bearer $newToken',
                  },
                  extra: {...request.extra, '__retried': true},
                  responseType: request.responseType,
                  contentType: request.contentType,
                ),
              );
              return handler.resolve(response);
            } on DioException catch (retryErr) {
              return handler.next(retryErr);
            }
          }

          // Refresh failed (expired/revoked refresh token) → sign out.
          ref.read(onUnauthorizedProvider)();
        }
        handler.next(err);
      },
    ),
  );

  return dio;
});
