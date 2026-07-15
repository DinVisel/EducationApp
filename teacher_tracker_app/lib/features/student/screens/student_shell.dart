import 'package:flutter/material.dart';

import '../../../core/design.dart';
import 'student_assignments_screen.dart';
import 'student_classes_screen.dart';
import 'student_profile_screen.dart';
import 'student_quizzes_screen.dart';

/// App shell for student accounts — bottom navigation across Assignments,
/// Classes, and Profile. Distinct from the teacher [HomeScreen].
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      StudentAssignmentsScreen(),
      StudentQuizzesScreen(),
      StudentClassesScreen(),
      StudentProfileScreen(),
    ];

    return GlassScaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          GlassNavDestination(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: 'Assignments',
          ),
          GlassNavDestination(
            icon: Icons.quiz_outlined,
            selectedIcon: Icons.quiz,
            label: 'Quizzes',
          ),
          GlassNavDestination(
            icon: Icons.class_outlined,
            selectedIcon: Icons.class_,
            label: 'Classes',
          ),
          GlassNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
