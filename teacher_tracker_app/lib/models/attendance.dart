/// A student's attendance state for a class day. Mirrors the backend
/// `AttendanceStatus` enum (serialized as its name).
enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusApi on AttendanceStatus {
  /// The wire value the API expects/returns (PascalCase).
  String get apiValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
    }
  }

  static AttendanceStatus? fromApi(String? value) {
    switch (value) {
      case 'Present':
        return AttendanceStatus.present;
      case 'Absent':
        return AttendanceStatus.absent;
      case 'Late':
        return AttendanceStatus.late;
      case 'Excused':
        return AttendanceStatus.excused;
      default:
        return null;
    }
  }
}

/// One student on the roster with their (possibly unmarked) status for a day.
/// Mirrors `AttendanceStudentDto`.
class AttendanceStudent {
  const AttendanceStudent({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.studentNumber,
    required this.status,
    required this.note,
  });

  final int studentId;
  final String firstName;
  final String lastName;
  final String studentNumber;
  final AttendanceStatus? status;
  final String? note;

  String get fullName => '$firstName $lastName'.trim();

  AttendanceStudent copyWith({AttendanceStatus? status, String? note}) =>
      AttendanceStudent(
        studentId: studentId,
        firstName: firstName,
        lastName: lastName,
        studentNumber: studentNumber,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) =>
      AttendanceStudent(
        studentId: json['studentId'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        studentNumber: json['studentNumber'] as String? ?? '',
        status: AttendanceStatusApi.fromApi(json['status'] as String?),
        note: json['note'] as String?,
      );
}

/// The class roster for a single day. Mirrors `AttendanceDayDto`.
class AttendanceDay {
  const AttendanceDay({required this.date, required this.students});

  final DateTime date;
  final List<AttendanceStudent> students;

  factory AttendanceDay.fromJson(Map<String, dynamic> json) => AttendanceDay(
        date: DateTime.parse(json['date'] as String),
        students: ((json['students'] as List<dynamic>?) ?? [])
            .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A single historical attendance record. Mirrors `AttendanceHistoryDto`.
class AttendanceHistory {
  const AttendanceHistory({
    required this.id,
    required this.date,
    required this.status,
    required this.note,
  });

  final int id;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) =>
      AttendanceHistory(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatusApi.fromApi(json['status'] as String?) ??
            AttendanceStatus.absent,
        note: json['note'] as String?,
      );
}
