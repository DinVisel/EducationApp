/// A school grade a shared material targets. Mirrors the backend `GradeLevel`
/// enum: [value] is the wire string, [label] is the display name.
class GradeLevel {
  const GradeLevel(this.value, this.label);

  final String value;
  final String label;

  /// All grades in display order (matches the backend enum order).
  static const List<GradeLevel> all = [
    GradeLevel('Kindergarten', 'Kindergarten'),
    GradeLevel('Grade1', 'Grade 1'),
    GradeLevel('Grade2', 'Grade 2'),
    GradeLevel('Grade3', 'Grade 3'),
    GradeLevel('Grade4', 'Grade 4'),
    GradeLevel('Grade5', 'Grade 5'),
    GradeLevel('Grade6', 'Grade 6'),
    GradeLevel('Grade7', 'Grade 7'),
    GradeLevel('Grade8', 'Grade 8'),
    GradeLevel('Grade9', 'Grade 9'),
    GradeLevel('Grade10', 'Grade 10'),
    GradeLevel('Grade11', 'Grade 11'),
    GradeLevel('Grade12', 'Grade 12'),
  ];

  /// The grade for a wire [value], or null if unknown/absent.
  static GradeLevel? fromValue(String? value) {
    if (value == null) return null;
    for (final g in all) {
      if (g.value == value) return g;
    }
    return null;
  }

  /// The display label for a wire [value], or null.
  static String? labelFor(String? value) => fromValue(value)?.label;
}
