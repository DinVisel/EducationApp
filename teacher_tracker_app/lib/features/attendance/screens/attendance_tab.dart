import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/attendance.dart';
import '../../../models/classroom.dart';
import '../data/attendance_repository.dart';
import '../state/attendance_providers.dart';
import 'attendance_history_screen.dart';

/// Daily attendance for a class: pick a date, set each student's status with a
/// quick toggle, and save the whole class at once.
class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({super.key, required this.classroom});

  final Classroom classroom;

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  // Local, unsaved edits keyed by student id (overlay the server statuses).
  final Map<int, AttendanceStatus> _edits = {};
  bool _saving = false;

  AttendanceDayArgs get _args =>
      (classroomId: widget.classroom.id, date: AttendanceRepository.formatDate(_date));

  AttendanceStatus? _statusFor(AttendanceStudent s) => _edits[s.studentId] ?? s.status;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _date = DateUtils.dateOnly(picked);
        _edits.clear();
      });
    }
  }

  Future<void> _save(List<AttendanceStudent> roster) async {
    final entries = [
      for (final s in roster)
        s.copyWith(status: _statusFor(s)),
    ];
    setState(() => _saving = true);
    final loc = AppLocalizations.of(context)!;
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .mark(widget.classroom.id, _date, entries);
      _edits.clear();
      ref.invalidate(attendanceDayProvider(_args));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.attendanceSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.attendanceSaveFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final dayAsync = ref.watch(attendanceDayProvider(_args));

    return dayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${loc.commonSomethingWentWrong}\n$e')),
      data: (day) {
        final roster = day.students;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(AttendanceRepository.formatDate(_date)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: roster.isEmpty
                        ? null
                        : () => setState(() {
                              for (final s in roster) {
                                _edits[s.studentId] = AttendanceStatus.present;
                              }
                            }),
                    child: Text(loc.attendanceMarkAllPresent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: roster.isEmpty
                  ? Center(child: Text(loc.attendanceEmptyRoster))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(attendanceDayProvider(_args).future),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: roster.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = roster[i];
                          return _AttendanceRow(
                            student: s,
                            status: _statusFor(s),
                            onChanged: (st) =>
                                setState(() => _edits[s.studentId] = st),
                            onHistory: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AttendanceHistoryScreen(
                                  classroomId: widget.classroom.id,
                                  studentId: s.studentId,
                                  studentName: s.fullName,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: FilledButton.icon(
                  onPressed: roster.isEmpty || _saving ? null : () => _save(roster),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(loc.attendanceSave),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One roster row: the student's name + a 4-way status toggle.
class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.student,
    required this.status,
    required this.onChanged,
    required this.onHistory,
  });

  final AttendanceStudent student;
  final AttendanceStatus? status;
  final ValueChanged<AttendanceStatus> onChanged;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(student.fullName,
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Icon(Icons.history, size: 20),
                tooltip: loc.attendanceViewHistory,
                onPressed: onHistory,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              for (final st in AttendanceStatus.values)
                ChoiceChip(
                  label: Text(_label(loc, st)),
                  selected: status == st,
                  onSelected: (_) => onChanged(st),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations loc, AttendanceStatus st) {
    switch (st) {
      case AttendanceStatus.present:
        return loc.attendanceStatusPresent;
      case AttendanceStatus.absent:
        return loc.attendanceStatusAbsent;
      case AttendanceStatus.late:
        return loc.attendanceStatusLate;
      case AttendanceStatus.excused:
        return loc.attendanceStatusExcused;
    }
  }
}
