import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/notifications_screen.dart';
import '../state/notifications_providers.dart';

/// A bell icon with an unread badge (polled). Tapping opens the notifications
/// screen, then refreshes the count. Drop into a screen header/app bar.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
