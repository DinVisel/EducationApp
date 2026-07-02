import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/student.dart';
import '../state/students_providers.dart';

/// Create (student == null) or edit an existing student, including the
/// detailed profile fields.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.student});

  final Student? student;

  bool get isEditing => student != null;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _studentNumber;
  late final TextEditingController _guardianName;
  late final TextEditingController _guardianPhone;
  late final TextEditingController _notes;
  DateTime? _dateOfBirth;
  String? _gender;
  bool _saving = false;

  static const _genders = ['Female', 'Male', 'Other'];

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _firstName = TextEditingController(text: s?.firstName ?? '');
    _lastName = TextEditingController(text: s?.lastName ?? '');
    _studentNumber = TextEditingController(text: s?.studentNumber ?? '');
    _guardianName = TextEditingController(text: s?.guardianName ?? '');
    _guardianPhone = TextEditingController(text: s?.guardianPhone ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
    _dateOfBirth = s?.dateOfBirth;
    _gender = _genders.contains(s?.gender) ? s?.gender : null;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _studentNumber.dispose();
    _guardianName.dispose();
    _guardianPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 8),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final notifier = ref.read(studentsProvider.notifier);

    // Build the values onto a draft/existing student.
    final base = widget.student ??
        const Student(
          id: 0,
          firstName: '',
          lastName: '',
          studentNumber: '',
          teacherId: 0,
        );
    final student = base.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      studentNumber: _studentNumber.text.trim(),
      dateOfBirth: _dateOfBirth,
      clearDateOfBirth: _dateOfBirth == null,
      gender: _gender ?? '',
      guardianName: _guardianName.text.trim(),
      guardianPhone: _guardianPhone.text.trim(),
      notes: _notes.text.trim(),
    );

    try {
      if (widget.isEditing) {
        await notifier.edit(student);
      } else {
        await notifier.add(student);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobLabel = _dateOfBirth == null
        ? 'Date of birth (optional)'
        : 'DOB: ${formatDateOnly(_dateOfBirth!)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit student' : 'Add student'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'First name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Last name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _studentNumber,
              decoration: const InputDecoration(
                labelText: 'Student number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDob,
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(dobLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (_dateOfBirth != null)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dateOfBirth = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                ..._genders.map(
                  (g) => DropdownMenuItem(value: g, child: Text(g)),
                ),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _guardianName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Guardian name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _guardianPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Guardian phone (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
