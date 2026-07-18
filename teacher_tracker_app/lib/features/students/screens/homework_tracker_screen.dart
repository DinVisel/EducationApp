import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/homework.dart';
import '../../../models/student.dart';
import '../state/homework_providers.dart';
import '../state/students_providers.dart';

/// Homework Tracker screen — matches the "Homework Tracker" Stitch screen.
/// Shows a weekly calendar picker and assignment cards with liquid progress bars.
class HomeworkTrackerScreen extends ConsumerStatefulWidget {
  const HomeworkTrackerScreen({super.key});

  @override
  ConsumerState<HomeworkTrackerScreen> createState() =>
      _HomeworkTrackerScreenState();
}

class _HomeworkTrackerScreenState extends ConsumerState<HomeworkTrackerScreen> {
  // Track selected student for filtering (null = show all)
  int? _selectedStudentId;
  int _weekOffset = 0;

  DateTime get _weekStart {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: _weekOffset * 7));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HomeworkAppBar(cs: cs, tt: tt)),
          // ── Header section ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.hwTrackerTitle,
                            style: tt.displaySmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 32)),
                        Text(loc.hwTrackerSubtitle,
                            style: tt.bodyLarge
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _addAssignment(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.hwTrackerNewAssignment),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40)),
                  ),
                ],
              ),
            ),
          ),
          // ── Weekly calendar ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(loc.hwTrackerThisWeek,
                            style: tt.titleLarge?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        IconButton(
                          icon:
                              Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
                          onPressed: () =>
                              setState(() => _weekOffset--),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.chevron_right,
                              color: cs.onSurfaceVariant),
                          onPressed: () =>
                              setState(() => _weekOffset++),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WeekdayPicker(weekStart: _weekStart, cs: cs, tt: tt),
                  ],
                ),
              ),
            ),
          ),
          // ── Student filter chips ─────────────────────────────────────
          studentsAsync.maybeWhen(
            data: (students) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: loc.hwTrackerAllStudents,
                        selected: _selectedStudentId == null,
                        onTap: () => setState(() => _selectedStudentId = null),
                        cs: cs,
                        tt: tt,
                      ),
                      ...students.map((s) => _FilterChip(
                            label: s.firstName,
                            selected: _selectedStudentId == s.id,
                            onTap: () =>
                                setState(() => _selectedStudentId = s.id),
                            cs: cs,
                            tt: tt,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            orElse: () => const SliverToBoxAdapter(child: SizedBox()),
          ),
          // ── Assignment cards ─────────────────────────────────────────
          studentsAsync.maybeWhen(
            data: (students) {
              final filtered = _selectedStudentId == null
                  ? students
                  : students.where((s) => s.id == _selectedStudentId).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _StudentHomeworkSection(
                    student: filtered[i],
                    cs: cs,
                    tt: tt,
                  ),
                  childCount: filtered.length,
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _addAssignment(BuildContext ctx, WidgetRef ref) async {
    final students = ref.read(studentsProvider).maybeWhen(
          data: (list) => list, orElse: () => <dynamic>[]);
    if (students.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx)!.readingAddStudentsFirst)));
      return;
    }
    // Default to first student or selected
    final targetId = _selectedStudentId ?? students.first.id;
    await showDialog(
      context: ctx,
      builder: (_) => _NewAssignmentDialog(
        students: students,
        initialStudentId: targetId,
        onSubmit: (studentId, title, desc, due) async {
          await ref.read(homeworkProvider(studentId).notifier).add(
                title: title,
                description: desc,
                dueDate: due,
              );
        },
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _HomeworkAppBar extends StatelessWidget {
  const _HomeworkAppBar({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 20, right: 20),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.menu_book, color: cs.primary),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.classTabHomework,
                  style: tt.headlineMedium?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                child: Icon(Icons.person, color: cs.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatefulWidget {
  const _WeekdayPicker(
      {required this.weekStart, required this.cs, required this.tt});
  final DateTime weekStart;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  State<_WeekdayPicker> createState() => _WeekdayPickerState();
}

class _WeekdayPickerState extends State<_WeekdayPicker> {
  int _selectedDay = DateTime.now().weekday - 1; // 0=Mon

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dayFormat = DateFormat('EEE', localeName);
    return Row(
      children: List.generate(5, (i) {
        final date = widget.weekStart.add(Duration(days: i));
        final isSelected = _selectedDay == i;
        final isToday = DateTime.now().day == date.day &&
            DateTime.now().month == date.month &&
            DateTime.now().year == date.year;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.cs.primary.withValues(alpha: 0.12)
                    : widget.cs.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(
                        color: widget.cs.primary.withValues(alpha: 0.3))
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(dayFormat.format(date),
                      style: widget.tt.labelSmall?.copyWith(
                          color: isSelected
                              ? widget.cs.primary
                              : widget.cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('${date.day}',
                      style: widget.tt.titleMedium?.copyWith(
                          color: isSelected
                              ? widget.cs.primary
                              : widget.cs.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400)),
                  if (isToday)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.cs.secondaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.cs,
      required this.tt});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(99),
          border: selected
              ? Border.all(color: cs.primary.withValues(alpha: 0.3))
              : Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: tt.labelMedium?.copyWith(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

class _StudentHomeworkSection extends ConsumerWidget {
  const _StudentHomeworkSection(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hwAsync = ref.watch(homeworkProvider(student.id));
    return hwAsync.maybeWhen(
      data: (homeworks) {
        if (homeworks.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          cs.primaryContainer.withValues(alpha: 0.4),
                      child: Text(
                        student.firstName.isNotEmpty
                            ? student.firstName[0]
                            : '?',
                        style: tt.labelMedium
                            ?.copyWith(color: cs.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(student.fullName,
                        style: tt.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              ...homeworks
                  .map((hw) => _HomeworkCard(
                        hw: hw,
                        onToggle: (v) => ref
                            .read(homeworkProvider(student.id).notifier)
                            .toggleDone(hw, v),
                        onDelete: () => ref
                            .read(homeworkProvider(student.id).notifier)
                            .remove(hw.id),
                        cs: cs,
                        tt: tt,
                      ))
                  .toList(),
            ],
          ),
        );
      },
      orElse: () => const SizedBox(),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.hw,
    required this.onToggle,
    required this.onDelete,
    required this.cs,
    required this.tt,
  });
  final Homework hw;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDone = hw.isDone;
    final progress = isDone ? 1.0 : 0.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        float: isDone,
        child: Opacity(
          opacity: isDone ? 0.7 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Subject chip
                  _SubjectChip(cs: cs, tt: tt),
                  const SizedBox(width: 8),
                  // Due tag
                  _DueChip(dueDate: hw.dueDate, isDone: isDone, cs: cs, tt: tt),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: cs.onSurfaceVariant),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(hw.title,
                  style: tt.titleMedium?.copyWith(
                      color: cs.onSurface,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : null)),
              if (hw.description != null && hw.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(hw.description!,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(isDone ? loc.hwTrackerCompleted : loc.hwTrackerInProgress,
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onSurface)),
                  const Spacer(),
                  Text('${(progress * 100).toInt()}%',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 6),
              LiquidProgressBar(value: progress),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onToggle(!isDone),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36)),
                      child: Text(
                          isDone ? loc.hwTrackerMarkUndone : loc.hwTrackerMarkDone),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Text(AppLocalizations.of(context)!.hwTrackerAssignmentChip,
          style: tt.labelSmall?.copyWith(color: cs.primary)),
    );
  }
}

class _DueChip extends StatelessWidget {
  const _DueChip(
      {required this.dueDate,
      required this.isDone,
      required this.cs,
      required this.tt});
  final DateTime? dueDate;
  final bool isDone;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final label = isDone
        ? loc.commonDone
        : dueDate == null
            ? loc.hwTrackerNoDueDate
            : loc.hwTrackerDue(formatDateOnly(dueDate!));
    final color = isDone ? cs.primary : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDone)
            Icon(Icons.check_circle,
                size: 12, color: cs.primary),
          if (isDone) const SizedBox(width: 4),
          Text(label,
              style: tt.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Add assignment dialog ─────────────────────────────────────────────────────

class _NewAssignmentDialog extends StatefulWidget {
  const _NewAssignmentDialog({
    required this.students,
    required this.initialStudentId,
    required this.onSubmit,
  });
  final List students;
  final int initialStudentId;
  final Future<void> Function(int studentId, String title, String? desc,
      DateTime? due) onSubmit;

  @override
  State<_NewAssignmentDialog> createState() => _NewAssignmentDialogState();
}

class _NewAssignmentDialogState extends State<_NewAssignmentDialog> {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _due;
  late int _studentId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.initialStudentId;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.hwTrackerNewAssignment),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _studentId,
              decoration: InputDecoration(labelText: loc.readingStudent),
              items: widget.students
                  .map<DropdownMenuItem<int>>((s) => DropdownMenuItem(
                        value: s.id as int,
                        child: Text(s.fullName as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _studentId = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: loc.commonTitle),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? loc.commonRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration:
                  InputDecoration(labelText: loc.commonDescriptionOptional),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _due ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 2),
                );
                if (picked != null) setState(() => _due = picked);
              },
              icon: const Icon(Icons.event),
              label: Text(_due == null
                  ? loc.hwTrackerPickDueDate
                  : loc.hwTrackerDue(formatDateOnly(_due!))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  if (!_key.currentState!.validate()) return;
                  setState(() => _loading = true);
                  try {
                    await widget.onSubmit(
                      _studentId,
                      _title.text.trim(),
                      _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                      _due,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.commonError('$e'))));
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc.commonAdd),
        ),
      ],
    );
  }
}
