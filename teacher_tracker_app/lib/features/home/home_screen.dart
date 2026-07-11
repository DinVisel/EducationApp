import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../classes/screens/classes_list_screen.dart';
import '../feed/screens/feed_screen.dart';
import '../teacher/screens/teacher_profile_screen.dart';

/// App shell with bottom navigation — 3 tabs: Hub, Classes, Profile.
/// Students, homework, and reading are reached through a class (class detail).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FeedScreen(),
      const ClassesListScreen(),
      const TeacherProfileScreen(),
    ];

    return GlassScaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
