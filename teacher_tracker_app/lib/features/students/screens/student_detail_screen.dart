import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/student.dart';
import '../state/students_providers.dart';
import 'student_form_screen.dart';
import 'tabs/books_tab.dart';
import 'tabs/homework_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/notes_tab.dart';

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
    final loc = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(current.fullName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: loc.studentDetailEditInfo,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudentFormScreen(student: current),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: const Icon(Icons.person_outline), text: loc.infoTabTitle),
              Tab(
                  icon: const Icon(Icons.sticky_note_2_outlined),
                  text: loc.studentProfileNotes),
              Tab(
                  icon: const Icon(Icons.assignment_outlined),
                  text: loc.classTabHomework),
              Tab(
                  icon: const Icon(Icons.menu_book_outlined),
                  text: loc.booksTabTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InfoTab(student: current),
            NotesTab(studentId: current.id),
            HomeworkTab(studentId: current.id),
            BooksTab(studentId: current.id),
          ],
        ),
      ),
    );
  }
}
