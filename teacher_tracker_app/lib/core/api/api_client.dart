import 'dart:async';

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

  // Retry interceptor for transient failures (added after the auth/401 one so a
  // 401 is resolved by the refresh flow above before we consider a retry). Only
  // idempotent requests are retried, so create/upload POSTs are never
  // double-sent.
  dio.interceptors.add(_RetryInterceptor(dio));

  return dio;
});

/// Retries idempotent requests on transient network failures — connection or
/// timeout errors, and 5xx responses — with exponential backoff. Non-idempotent
/// methods (POST/PUT/PATCH/DELETE) are retried only when the caller explicitly
/// opts in via `Options(extra: {'__retriable': true})`.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  static const _maxRetries = 2;
  static const _baseDelay = Duration(milliseconds: 400);

  bool _isTransient(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        return code >= 500 && code <= 599;
      default:
        return false;
    }
  }

  bool _isIdempotent(RequestOptions options) {
    if (options.extra['__retriable'] == true) return true;
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'HEAD';
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final attempt = (options.extra['__retryAttempt'] as int?) ?? 0;

    final cancelled = options.cancelToken?.isCancelled ?? false;
    if (cancelled ||
        attempt >= _maxRetries ||
        !_isTransient(err) ||
        !_isIdempotent(options)) {
      return handler.next(err);
    }

    // Exponential backoff: 400ms, then 800ms.
    await Future<void>.delayed(_baseDelay * (1 << attempt));
    if (options.cancelToken?.isCancelled ?? false) {
      return handler.next(err);
    }

    options.extra['__retryAttempt'] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }
}
