import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/student.dart';
import '../state/students_providers.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reflect edits made on the form by re-reading the latest copy from state.
    final current = ref.watch(studentsProvider).maybeWhen(
          data: (list) => list.firstWhere(
            (s) => s.id == student.id,
            orElse: () => student,
          ),
          orElse: () => student,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(current.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentFormScreen(student: current),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'First name',
            value: current.firstName,
          ),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'Last name',
            value: current.lastName,
          ),
          _InfoTile(
            icon: Icons.numbers,
            label: 'Student number',
            value: current.studentNumber.isEmpty ? '—' : current.studentNumber,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
