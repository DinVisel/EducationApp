import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/attendance.dart';
import '../../auth/state/auth_controller.dart';
import '../data/attendance_repository.dart';

/// (classroomId, `yyyy-MM-dd`) key for a day's roster.
typedef AttendanceDayArgs = ({int classroomId, String date});

/// The class roster + statuses for one day. Rebuilds on session change.
final attendanceDayProvider = FutureProvider.autoDispose
    .family<AttendanceDay, AttendanceDayArgs>((ref, args) async {
  ref.watch(authControllerProvider); // reload on login/logout
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getDay(args.classroomId, DateTime.parse(args.date));
});

/// (classroomId, studentId) key for a student's history.
typedef AttendanceHistoryArgs = ({int classroomId, int studentId});

/// A single student's attendance history in a class (most recent first).
final attendanceHistoryProvider = FutureProvider.autoDispose
    .family<List<AttendanceHistory>, AttendanceHistoryArgs>((ref, args) async {
  ref.watch(authControllerProvider);
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.history(args.classroomId, args.studentId);
});
