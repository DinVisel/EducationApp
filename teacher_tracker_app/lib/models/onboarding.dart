// Models for the hybrid student onboarding flows (mirrors the backend's
// OnboardingDtos). Method A = Access Card; Method B = Class Code & Lobby.

/// Mirrors `AccessCardDto`. [qrToken] is the raw QR secret, present only in the
/// response that created/rotated the card (never re-listed) — null otherwise.
class AccessCard {
  const AccessCard({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.accessCode,
    this.qrToken,
  });

  final int studentId;
  final String firstName;
  final String lastName;
  final String accessCode;
  final String? qrToken;

  String get fullName => '$firstName $lastName'.trim();

  factory AccessCard.fromJson(Map<String, dynamic> json) => AccessCard(
        studentId: (json['studentId'] as num?)?.toInt() ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        accessCode: json['accessCode'] as String? ?? '',
        qrToken: json['qrToken'] as String?,
      );
}

/// Mirrors `LobbyEntryDto` — a pending join request as the teacher sees it.
class LobbyEntry {
  const LobbyEntry({
    required this.requestId,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.createdAt,
  });

  final int requestId;
  final int studentId;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime createdAt;

  String get fullName => '$firstName $lastName'.trim();

  factory LobbyEntry.fromJson(Map<String, dynamic> json) => LobbyEntry(
        requestId: (json['requestId'] as num).toInt(),
        studentId: (json['studentId'] as num).toInt(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Mirrors `ClassJoinRequestDto` — a join request as the student sees it.
class ClassJoinRequest {
  const ClassJoinRequest({
    required this.id,
    required this.classroomId,
    required this.className,
    required this.teacherName,
    required this.status,
    required this.createdAt,
    required this.decidedAt,
  });

  final int id;
  final int classroomId;
  final String className;
  final String teacherName;
  final String status; // Pending | Approved | Rejected
  final DateTime createdAt;
  final DateTime? decidedAt;

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  factory ClassJoinRequest.fromJson(Map<String, dynamic> json) =>
      ClassJoinRequest(
        id: (json['id'] as num).toInt(),
        classroomId: (json['classroomId'] as num).toInt(),
        className: json['className'] as String? ?? '',
        teacherName: json['teacherName'] as String? ?? '',
        status: json['status'] as String? ?? 'Pending',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        decidedAt: json['decidedAt'] == null
            ? null
            : DateTime.tryParse(json['decidedAt'] as String),
      );
}
