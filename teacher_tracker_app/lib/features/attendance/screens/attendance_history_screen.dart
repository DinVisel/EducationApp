import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/attendance.dart';
import '../data/attendance_repository.dart';
import '../state/attendance_providers.dart';

/// One student's attendance history in a class, most recent first.
class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({
    super.key,
    required this.classroomId,
    required this.studentId,
    required this.studentName,
  });

  final int classroomId;
  final int studentId;
  final String studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final args = (classroomId: classroomId, studentId: studentId);
    final historyAsync = ref.watch(attendanceHistoryProvider(args));

    return GlassScaffold(
      appBar: AppBar(
        title: Text(loc.attendanceHistoryTitle),
        backgroundColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${loc.commonSomethingWentWrong}\n$e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(child: Text(loc.attendanceHistoryEmpty));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(attendanceHistoryProvider(args).future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: records.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Text(studentName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700));
                }
                return _HistoryRow(record: records[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final AttendanceHistory record;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(_icon(record.status), color: _color(record.status, cs), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AttendanceRepository.formatDate(record.date),
                    style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (record.note != null && record.note!.isNotEmpty)
                  Text(record.note!,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(_label(loc, record.status),
              style: tt.labelLarge
                  ?.copyWith(color: _color(record.status, cs))),
        ],
      ),
    );
  }

  IconData _icon(AttendanceStatus st) {
    switch (st) {
      case AttendanceStatus.present:
        return Icons.check_circle_outline;
      case AttendanceStatus.absent:
        return Icons.cancel_outlined;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.excused:
        return Icons.event_available_outlined;
    }
  }

  Color _color(AttendanceStatus st, ColorScheme cs) {
    switch (st) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return cs.error;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return cs.primary;
    }
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
