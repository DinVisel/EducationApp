import 'package:flutter/material.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import 'student_assignments_screen.dart';
import 'student_classes_screen.dart';
import 'student_home_screen.dart';
import 'student_profile_screen.dart';
import 'student_quizzes_screen.dart';

/// App shell for student accounts — bottom navigation across Home, Assignments,
/// Quizzes, Classes, and Profile. Distinct from the teacher [HomeScreen].
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeScreen(onNavigate: (i) => setState(() => _index = i)),
      const StudentAssignmentsScreen(),
      const StudentQuizzesScreen(),
      const StudentClassesScreen(),
      const StudentProfileScreen(),
    ];
    final loc = AppLocalizations.of(context)!;

    return GlassScaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          GlassNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: loc.stuHome,
          ),
          GlassNavDestination(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: loc.stuAssignments,
          ),
          GlassNavDestination(
            icon: Icons.quiz_outlined,
            selectedIcon: Icons.quiz,
            label: loc.classTabQuizzes,
          ),
          GlassNavDestination(
            icon: Icons.class_outlined,
            selectedIcon: Icons.class_,
            label: loc.classesTitle,
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
}
