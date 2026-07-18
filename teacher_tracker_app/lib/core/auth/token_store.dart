import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access token + its refresh token securely and keeps an
/// in-memory copy of each so the Dio interceptor can read them synchronously.
class TokenStore {
  TokenStore(this._storage);

  static const _accessKey = 'auth_token';
  static const _refreshKey = 'refresh_token';
  final FlutterSecureStorage _storage;
  String? _cachedAccess;
  String? _cachedRefresh;

  /// The access token currently held in memory (null if signed out).
  String? get current => _cachedAccess;

  /// The refresh token currently held in memory (null if signed out).
  String? get currentRefresh => _cachedRefresh;

  /// Loads both tokens from secure storage into memory (called at startup).
  /// Returns the access token for convenience.
  Future<String?> load() async {
    _cachedAccess = await _storage.read(key: _accessKey);
    _cachedRefresh = await _storage.read(key: _refreshKey);
    return _cachedAccess;
  }

  /// Persists a freshly issued access + refresh token pair.
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _cachedAccess = accessToken;
    _cachedRefresh = refreshToken;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  /// Updates just the access token (e.g. mid-flight after a silent refresh that
  /// hasn't yet returned a new refresh token). Kept for symmetry; refresh
  /// responses normally rotate both, so prefer [saveTokens].
  Future<void> saveAccess(String accessToken) async {
    _cachedAccess = accessToken;
    await _storage.write(key: _accessKey, value: accessToken);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(const FlutterSecureStorage()),
);
