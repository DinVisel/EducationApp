/// School type a teacher works at. Mirrors the backend `SchoolType` enum
/// (serialized as its name, e.g. "State").
enum SchoolType {
  state,
  private,
  other;

  /// The wire value expected by the API (PascalCase, matching the C# enum).
  String get wire => switch (this) {
        SchoolType.state => 'State',
        SchoolType.private => 'Private',
        SchoolType.other => 'Other',
      };

  static SchoolType? fromWire(String? value) => switch (value) {
        'State' => SchoolType.state,
        'Private' => SchoolType.private,
        'Other' => SchoolType.other,
        _ => null,
      };
}

/// Education level(s) a teacher teaches. Mirrors the backend `EducationLevel`.
enum EducationLevel {
  primarySchool,
  middleSchool,
  both;

  String get wire => switch (this) {
        EducationLevel.primarySchool => 'PrimarySchool',
        EducationLevel.middleSchool => 'MiddleSchool',
        EducationLevel.both => 'Both',
      };

  static EducationLevel? fromWire(String? value) => switch (value) {
        'PrimarySchool' => EducationLevel.primarySchool,
        'MiddleSchool' => EducationLevel.middleSchool,
        'Both' => EducationLevel.both,
        _ => null,
      };
}

/// Mirrors `TeacherDto` from the backend (camelCase JSON).
class Teacher {
  const Teacher({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarFileId,
    this.coverFileId,
    this.city,
    this.district,
    this.schoolType,
    this.educationLevel,
    this.requiresProfileSetup = false,
  });

  final int id;

  /// The account (User) id — matches a post's `authorUserId`.
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final int? avatarFileId;
  final int? coverFileId;

  /// Demographic profile fields (null until the teacher fills them in).
  final String? city;
  final String? district;
  final SchoolType? schoolType;
  final EducationLevel? educationLevel;

  /// Whether this account is subject to the mandatory demographic onboarding
  /// gate. False for grandfathered (pre-feature) accounts — server-controlled.
  final bool requiresProfileSetup;

  String get fullName => '$firstName $lastName'.trim();

  /// Whether the mandatory demographic profile has been filled in. Drives the
  /// first-login onboarding gate (see the router in app.dart): a teacher can't
  /// enter the app until City, District, School type and Education level are set.
  bool get hasCompletedDemographics =>
      (city?.trim().isNotEmpty ?? false) &&
      (district?.trim().isNotEmpty ?? false) &&
      schoolType != null &&
      educationLevel != null;

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarFileId: json['avatarFileId'] as int?,
        coverFileId: json['coverFileId'] as int?,
        city: json['city'] as String?,
        district: json['district'] as String?,
        schoolType: SchoolType.fromWire(json['schoolType'] as String?),
        educationLevel:
            EducationLevel.fromWire(json['educationLevel'] as String?),
        requiresProfileSetup: json['requiresProfileSetup'] as bool? ?? false,
      );

  /// Body for create/update (server assigns `id`). Includes the image ids so a
  /// profile-image change is persisted; nulls leave the server value unchanged.
  Map<String, dynamic> toWriteJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'avatarFileId': ?avatarFileId,
        'coverFileId': ?coverFileId,
        'city': ?city,
        'district': ?district,
        'schoolType': ?schoolType?.wire,
        'educationLevel': ?educationLevel?.wire,
      };

  Teacher copyWith({
    String? firstName,
    String? lastName,
    String? email,
    int? avatarFileId,
    int? coverFileId,
    String? city,
    String? district,
    SchoolType? schoolType,
    EducationLevel? educationLevel,
    bool? requiresProfileSetup,
  }) =>
      Teacher(
        id: id,
        userId: userId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        avatarFileId: avatarFileId ?? this.avatarFileId,
        coverFileId: coverFileId ?? this.coverFileId,
        city: city ?? this.city,
        district: district ?? this.district,
        schoolType: schoolType ?? this.schoolType,
        educationLevel: educationLevel ?? this.educationLevel,
        requiresProfileSetup: requiresProfileSetup ?? this.requiresProfileSetup,
      );
}
