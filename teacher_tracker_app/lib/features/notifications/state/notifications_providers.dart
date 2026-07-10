import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification.dart';
import '../../auth/state/auth_controller.dart';
import '../data/notifications_repository.dart';

/// The signed-in user's notifications, newest first.
final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) {
  // Reload on login/logout.
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null) return Future.value(const []);
  return ref.watch(notificationsRepositoryProvider).getAll();
});

/// The unread badge count, polled every 30s while signed in.
final unreadCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final auth = ref.watch(authControllerProvider).value;
  if (auth == null) {
    yield 0;
    return;
  }
  final repo = ref.watch(notificationsRepositoryProvider);

  // Emit immediately, then poll.
  yield await repo.unreadCount();
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await repo.unreadCount();
  }
});
