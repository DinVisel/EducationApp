import 'package:flutter/material.dart';

import '../../../../models/student.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final dob = student.dateOfBirth;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tile(Icons.badge_outlined, 'Full name', student.fullName),
        _tile(Icons.numbers, 'Student number',
            _orDash(student.studentNumber)),
        _tile(
          Icons.cake_outlined,
          'Date of birth',
          dob == null
              ? '—'
              : '${formatDateOnly(dob)}  (age ${_age(dob)})',
        ),
        _tile(Icons.wc_outlined, 'Gender', _orDash(student.gender)),
        _tile(Icons.person_outline, 'Guardian', _orDash(student.guardianName)),
        _tile(Icons.phone_outlined, 'Guardian phone',
            _orDash(student.guardianPhone)),
        _tile(Icons.notes_outlined, 'Notes', _orDash(student.notes)),
      ],
    );
  }

  static Widget _tile(IconData icon, String label, String value) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          subtitle: Text(value),
          isThreeLine: value.length > 40,
        ),
      );

  static String _orDash(String? v) =>
      (v == null || v.trim().isEmpty) ? '—' : v.trim();

  static int _age(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
