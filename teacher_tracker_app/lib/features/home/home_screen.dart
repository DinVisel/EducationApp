import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../classes/screens/classes_list_screen.dart';
import '../feed/screens/feed_screen.dart';
import '../students/screens/student_dashboard_screen.dart';
import '../students/screens/homework_tracker_screen.dart';
import '../students/screens/reading_log_screen.dart';
import '../teacher/screens/teacher_profile_screen.dart';

/// App shell with bottom navigation — 6 tabs:
/// Hub, Students, Classes, Homework, Reading, Profile.
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
      const StudentDashboardScreen(),
      const ClassesListScreen(),
      const HomeworkTrackerScreen(),
      const ReadingLogScreen(),
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
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Reading',
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
