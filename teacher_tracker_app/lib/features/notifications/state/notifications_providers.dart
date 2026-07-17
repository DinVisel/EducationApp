import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification.dart';
import '../../auth/state/auth_controller.dart';
import '../data/notifications_repository.dart';

/// The signed-in user's notifications, newest first, with cursor pagination.
/// Rebuilds when the session changes.
class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  static const _pageSize = 20;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<AppNotification>> build() async {
    // Rebuild on login/logout; only load when signed in.
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null) return [];
    final page =
        await ref.read(notificationsRepositoryProvider).getAll(limit: _pageSize);
    _hasMore = page.length == _pageSize;
    return page;
  }

  /// Appends the next page after the last-loaded notification.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isEmpty || !_hasMore) return;

    final next = await ref
        .read(notificationsRepositoryProvider)
        .getAll(beforeId: current.last.id, limit: _pageSize);
    _hasMore = next.length == _pageSize;
    state = AsyncData([...current, ...next]);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

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
