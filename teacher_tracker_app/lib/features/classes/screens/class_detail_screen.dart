import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/classroom.dart';
import '../../../models/student.dart';
import '../../attendance/screens/attendance_tab.dart';
import '../../quizzes/screens/class_quizzes_tab.dart';
import '../../students/screens/student_detail_screen.dart';
import '../../students/state/students_providers.dart';
import '../state/classrooms_providers.dart';
import 'access_cards_screen.dart';
import 'class_lobby_screen.dart';
import 'tabs/class_homework_tab.dart';
import 'tabs/class_reading_tab.dart';

/// A class hub, tabbed into Students / Homework / Reading. The Students tab is
/// the roster (tap a student for their detail + reading log); Homework and
/// Reading aggregate the roster's work.
class ClassDetailScreen extends ConsumerStatefulWidget {
  const ClassDetailScreen({super.key, required this.classroom});

  final Classroom classroom;

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this)
    ..addListener(() => setState(() {}));

  Classroom get classroom => widget.classroom;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(classroom.name),
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Onboarding',
            onSelected: (value) => _onMenu(context, value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'code',
                child: ListTile(
                  leading: Icon(Icons.qr_code_2),
                  title: Text('Class code'),
                  subtitle: Text('Share so students can request to join'),
                ),
              ),
              PopupMenuItem(
                value: 'cards',
                child: ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Access cards'),
                  subtitle: Text('Code/QR logins for young students'),
                ),
              ),
              PopupMenuItem(
                value: 'lobby',
                child: ListTile(
                  leading: Icon(Icons.hourglass_top),
                  title: Text('Waiting lobby'),
                  subtitle: Text('Approve students who entered the code'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(
                icon: const Icon(Icons.groups_outlined),
                text: loc.classTabStudents),
            Tab(
                icon: const Icon(Icons.assignment_outlined),
                text: loc.classTabHomework),
            Tab(
                icon: const Icon(Icons.quiz_outlined),
                text: loc.classTabQuizzes),
            Tab(
                icon: const Icon(Icons.auto_stories_outlined),
                text: loc.classTabReading),
            Tab(
              icon: const Icon(Icons.fact_check_outlined),
              text: loc.attendanceTabLabel,
            ),
          ],
        ),
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _addStudents(context, ref),
              icon: const Icon(Icons.person_add_alt),
              label: Text(loc.classAddStudents),
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          _RosterTab(
            classroom: classroom,
            onRemove: (s) => _removeStudent(context, ref, s),
          ),
          ClassHomeworkTab(classroom: classroom),
          ClassQuizzesTab(classroom: classroom),
          ClassReadingTab(classroom: classroom),
          AttendanceTab(classroom: classroom),
        ],
      ),
    );
  }

  Future<void> _removeStudent(
      BuildContext ctx, WidgetRef ref, Student s) async {
    try {
      await ref
          .read(classroomsProvider.notifier)
          .unenroll(classroom.id, s.id);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(ctx)!.classCouldNotRemove('$e'))));
      }
    }
  }

  void _onMenu(BuildContext context, String value) {
    switch (value) {
      case 'code':
        _showClassCode(context);
      case 'cards':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AccessCardsScreen(
              classroomId: classroom.id, className: classroom.name),
        ));
      case 'lobby':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ClassLobbyScreen(
              classroomId: classroom.id, className: classroom.name),
        ));
    }
  }

  // The global class code lives on the roster detail (ClassroomDetailDto).
  void _showClassCode(BuildContext context) {
    final detail = ref.read(classroomDetailProvider(classroom.id)).value;
    final code = detail?.classCode ?? '';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Class code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Older students enter this code in the app to request '
                'to join. You approve them from the Waiting lobby.'),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              code.isEmpty ? '—' : code,
              style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold, letterSpacing: 6),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: code.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Class code copied.')));
                  },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
          TextButton.icon(
            onPressed: code.isEmpty
                ? null
                : () => Share.share(
                    'Join my class "${classroom.name}" with code $code'),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _addStudents(BuildContext context, WidgetRef ref) async {
    final detail = ref.read(classroomDetailProvider(classroom.id)).value;
    final enrolledIds = {for (final s in detail?.students ?? <Student>[]) s.id};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddStudentsSheet(
        classroomId: classroom.id,
        enrolledIds: enrolledIds,
      ),
    );
  }
}

/// The roster list for the Students tab; tapping a student opens their detail.
class _RosterTab extends ConsumerWidget {
  const _RosterTab({required this.classroom, required this.onRemove});
  final Classroom classroom;
  final void Function(Student) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(classroomDetailProvider(classroom.id));
    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(loc.commonError('$e'))),
      data: (detail) {
        if (detail.students.isEmpty) return const _EmptyRoster();
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(classroomDetailProvider(classroom.id).future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: detail.students.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final s = detail.students[i];
              return _RosterTile(
                student: s,
                onRemove: () => onRemove(s),
                onTap: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => StudentDetailScreen(student: s),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RosterTile extends StatelessWidget {
  const _RosterTile({
    required this.student,
    required this.onRemove,
    required this.onTap,
  });
  final Student student;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
            child: Text(_initials(student),
                style: tt.labelLarge?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (student.studentNumber.isNotEmpty)
                  Text(
                      AppLocalizations.of(context)!
                          .classStudentNumber(student.studentNumber),
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: cs.error),
            tooltip: AppLocalizations.of(context)!.classRemoveFromClass,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}

/// Bottom sheet listing the teacher's students who aren't in the class yet.
class _AddStudentsSheet extends ConsumerWidget {
  const _AddStudentsSheet({
    required this.classroomId,
    required this.enrolledIds,
  });

  final int classroomId;
  final Set<int> enrolledIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsProvider);
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: studentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(loc.commonError('$e')),
          ),
          data: (students) {
            final available =
                students.where((s) => !enrolledIds.contains(s.id)).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(loc.classAddStudentsSheetTitle,
                      style: tt.titleLarge),
                ),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Text(loc.classAllStudentsEnrolled),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: available.length,
                      itemBuilder: (ctx, i) {
                        final s = available[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text(_initials(s))),
                          title: Text(s.fullName),
                          subtitle: s.studentNumber.isEmpty
                              ? null
                              : Text(loc.classStudentNumber(s.studentNumber)),
                          trailing: const Icon(Icons.add),
                          onTap: () => _enroll(ctx, ref, s),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _enroll(BuildContext ctx, WidgetRef ref, Student s) async {
    try {
      await ref.read(classroomsProvider.notifier).enroll(classroomId, s.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(ctx)!.classStudentAdded(s.fullName))),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(ctx)!.classCouldNotAdd('$e'))));
      }
    }
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.groups_outlined,
            size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Center(
          child: Text(loc.classEmptyRosterTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(loc.classEmptyRosterSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}
