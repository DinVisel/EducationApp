import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../auth/state/auth_controller.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';

/// App shell for admin accounts — moderation reports and the user roster, plus
/// sign-out. Distinct from the teacher and student shells.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [AdminReportsScreen(), AdminUsersScreen()];

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          GlassNavDestination(
            icon: Icons.flag_outlined,
            selectedIcon: Icons.flag,
            label: 'Reports',
          ),
          GlassNavDestination(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
