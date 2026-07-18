import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/notification_hub.dart';
import '../screens/notifications_screen.dart';
import '../state/notifications_providers.dart';

/// A bell icon with an unread badge. Tapping opens the notifications screen,
/// then refreshes the count. Drop into a screen header/app bar. Watching this
/// also activates the real-time SignalR hub (which pushes badge updates and
/// falls back to the 30s poll when the socket is down).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the real-time hub alive while a signed-in shell shows the bell.
    ref.watch(notificationHubProvider);
    final count = ref.watch(unreadCountProvider).value ?? 0;
    final cs = Theme.of(context).colorScheme;

    final bell = IconButton(
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Notifications',
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        ref.invalidate(unreadCountProvider);
      },
    );

    if (count == 0) return bell;

    return Badge.count(
      count: count,
      backgroundColor: cs.error,
      alignment: Alignment.topRight,
      offset: const Offset(-6, 6),
      child: bell,
    );
  }
}
