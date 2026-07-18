import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../auth/token_store.dart';
import '../config.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/notifications/state/notifications_providers.dart';

/// Maintains a SignalR connection to the backend notifications hub. The server
/// pushes a payload-free "notification" signal to the current user; on receipt
/// we invalidate the notification providers so they re-fetch over REST. The 30s
/// poll in [unreadCountProvider] stays as a fallback for when the socket is down.
class NotificationHub {
  NotificationHub(this._ref);

  final Ref _ref;
  HubConnection? _connection;
  bool _connecting = false;

  Future<void> connect() async {
    if (_connection != null || _connecting) return;
    if (_ref.read(tokenStoreProvider).current == null) return;

    _connecting = true;
    final connection = HubConnectionBuilder()
        .withUrl(
          '$apiBaseUrl/hubs/notifications',
          options: HttpConnectionOptions(
            // Re-read on every (re)connect so a refreshed access token is used.
            accessTokenFactory: () async =>
                _ref.read(tokenStoreProvider).current ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('notification', (_) {
      _ref.invalidate(unreadCountProvider);
      _ref.invalidate(notificationsProvider);
    });

    try {
      await connection.start();
      _connection = connection;
    } catch (_) {
      // Couldn't establish the socket — polling still covers us.
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    await connection?.stop();
  }
}

/// Owns the hub lifecycle: connects while signed in, disconnects on sign-out.
/// Watch this from a widget that's present whenever a user is signed in (e.g.
/// the notification bell) to activate it.
final notificationHubProvider = Provider<NotificationHub>((ref) {
  final hub = NotificationHub(ref);

  ref.listen<AsyncValue<AuthState?>>(authControllerProvider, (_, next) {
    if (next.value != null) {
      hub.connect();
    } else {
      hub.disconnect();
    }
  }, fireImmediately: true);

  ref.onDispose(hub.disconnect);
  return hub;
});
