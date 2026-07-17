import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../l10n/app_localizations.dart';
import '../classes/screens/classes_list_screen.dart';
import '../feed/screens/feed_screen.dart';
import '../search/screens/search_screen.dart';
import '../teacher/screens/teacher_profile_screen.dart';

/// App shell with bottom navigation — 4 tabs: Hub, Search, Classes, Profile.
/// Students, homework, and reading are reached through a class (class detail).
///
/// Owns the floating action button (swapped per tab) rather than letting
/// each tab page have its own: the FAB and the nav bar must live in the same
/// [Scaffold] for Flutter's default FAB placement to auto-avoid the nav bar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final pages = [
      const FeedScreen(),
      const SearchScreen(),
      const ClassesListScreen(),
      const TeacherProfileScreen(),
    ];

    return GlassScaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _fabForIndex(_index, loc),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: [
          GlassNavDestination(
            icon: Icons.forum_outlined,
            selectedIcon: Icons.forum,
            label: loc.navHub,
          ),
          GlassNavDestination(
            icon: Icons.search,
            selectedIcon: Icons.search,
            label: loc.navSearch,
          ),
          GlassNavDestination(
            icon: Icons.class_outlined,
            selectedIcon: Icons.class_,
            label: loc.navClasses,
          ),
          GlassNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: loc.navProfile,
          ),
        ],
      ),
    );
  }

  Widget? _fabForIndex(int index, AppLocalizations loc) {
    switch (index) {
      case 0:
        return FloatingActionButton.extended(
          key: const ValueKey('fab-new-post'),
          onPressed: () => openNewPost(context),
          icon: const Icon(Icons.post_add),
          label: Text(loc.navNewPost),
        );
      case 2:
        return FloatingActionButton.extended(
          key: const ValueKey('fab-new-class'),
          onPressed: () => createClass(context, ref),
          icon: const Icon(Icons.add),
          label: Text(loc.navNewClass),
        );
      default:
        return null;
    }
  }
}
