import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` while the device has some network transport (wifi/mobile/etc.)
/// and `false` when it drops to none. Seeded with an initial synchronous-ish
/// check so the first value is accurate rather than optimistic.
///
/// Note: this reflects link availability, not reachability of our API — a
/// captive portal or dead server still reports online. The Dio retry
/// interceptor covers those transient failures; this drives the global banner.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  bool online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
});
