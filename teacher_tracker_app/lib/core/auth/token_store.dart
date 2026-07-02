import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT securely and keeps an in-memory copy so the Dio
/// interceptor can read it synchronously on each request.
class TokenStore {
  TokenStore(this._storage);

  static const _key = 'auth_token';
  final FlutterSecureStorage _storage;
  String? _cached;

  /// The token currently held in memory (null if signed out).
  String? get current => _cached;

  /// Loads the token from secure storage into memory (called at startup).
  Future<String?> load() async {
    _cached = await _storage.read(key: _key);
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(const FlutterSecureStorage()),
);
