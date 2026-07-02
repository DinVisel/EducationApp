/// Mirrors `StudentDto` from the backend (camelCase JSON).
class Student {
  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.studentNumber,
    required this.teacherId,
    this.dateOfBirth,
    this.gender,
    this.guardianName,
    this.guardianPhone,
    this.notes,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String studentNumber;
  final int teacherId;

  // Detailed profile (all optional).
  final DateTime? dateOfBirth;
  final String? gender;
  final String? guardianName;
  final String? guardianPhone;
  final String? notes;

  String get fullName => '$firstName $lastName'.trim();

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as int,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        studentNumber: json['studentNumber'] as String? ?? '',
        teacherId: json['teacherId'] as int,
        dateOfBirth: _parseDate(json['dateOfBirth']),
        gender: json['gender'] as String?,
        guardianName: json['guardianName'] as String?,
        guardianPhone: json['guardianPhone'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> _writeFields() => {
        'firstName': firstName,
        'lastName': lastName,
        'studentNumber': studentNumber,
        'dateOfBirth': dateOfBirth == null ? null : _formatDate(dateOfBirth!),
        'gender': _blankToNull(gender),
        'guardianName': _blankToNull(guardianName),
        'guardianPhone': _blankToNull(guardianPhone),
        'notes': _blankToNull(notes),
      };

  /// Body for POST /api/students (teacherId assigned server-side).
  Map<String, dynamic> toCreateJson() => _writeFields();

  /// Body for PUT /api/students/{id}.
  Map<String, dynamic> toUpdateJson() => _writeFields();

  Student copyWith({
    String? firstName,
    String? lastName,
    String? studentNumber,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? gender,
    String? guardianName,
    String? guardianPhone,
    String? notes,
  }) =>
      Student(
        id: id,
        teacherId: teacherId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        studentNumber: studentNumber ?? this.studentNumber,
        dateOfBirth:
            clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
        gender: gender ?? this.gender,
        guardianName: guardianName ?? this.guardianName,
        guardianPhone: guardianPhone ?? this.guardianPhone,
        notes: notes ?? this.notes,
      );
}

/// Formats a date as `yyyy-MM-dd` for the backend's DateOnly fields.
String formatDateOnly(DateTime d) => _formatDate(d);

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String? _blankToNull(String? v) {
  if (v == null) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}
