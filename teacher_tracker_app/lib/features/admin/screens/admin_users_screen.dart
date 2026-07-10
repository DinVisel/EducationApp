import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/admin_user.dart';
import '../state/admin_providers.dart';

/// Read-only roster of every account, for admin oversight.
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminUsersProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 24, 20, 8),
                child: Text('Users',
                    style: tt.headlineMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
              ),
            ),
            ...async.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Error: $e')),
                ),
              ],
              data: (users) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _UserCard(user: users[i]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
            child: Icon(_iconFor(user.role), color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name?.trim().isNotEmpty == true ? user.name! : user.email,
                    style: tt.titleSmall?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
                Text(user.email,
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(user.role,
                style: tt.labelSmall?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String role) {
    switch (role) {
      case 'Admin':
        return Icons.shield_outlined;
      case 'Student':
        return Icons.school_outlined;
      default:
        return Icons.person_outline;
    }
  }
}
