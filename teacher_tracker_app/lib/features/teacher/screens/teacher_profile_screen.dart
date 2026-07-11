import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/teacher.dart';
import '../../auth/state/auth_controller.dart';
import '../../files/data/files_repository.dart';
import '../../files/mime.dart';
import '../../profile/widgets/profile_cover_header.dart';
import '../../profile/widgets/teacher_posts_list.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(currentTeacherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: teacher == null
          ? const Center(child: CircularProgressIndicator())
          : _ProfileForm(teacher: teacher),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.teacher});

  final Teacher teacher;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.teacher.firstName);
    _lastName = TextEditingController(text: widget.teacher.lastName);
    _email = TextEditingController(text: widget.teacher.email);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            widget.teacher.copyWith(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Pick an image, upload it to R2, then persist it as the avatar or cover.
  Future<void> _changeImage({required bool cover}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingImage = true);
    try {
      final uploaded = await ref.read(filesRepositoryProvider).uploadDirect(
            bytes: bytes,
            fileName: f.name,
            contentType: mimeForFileName(f.name),
          );
      await ref.read(authControllerProvider.notifier).updateProfile(
            cover
                ? widget.teacher.copyWith(coverFileId: uploaded.id)
                : widget.teacher.copyWith(avatarFileId: uploaded.id),
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ProfileCoverHeader(
            name: widget.teacher.fullName,
            subtitle: widget.teacher.email,
            initials: _initials(),
            avatarFileId: widget.teacher.avatarFileId,
            coverFileId: widget.teacher.coverFileId,
            busy: _uploadingImage,
            onEditCover: () => _changeImage(cover: true),
            onEditAvatar: () => _changeImage(cover: false),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
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
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
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
                        : const Text('Save changes'),
                  ),
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Your posts',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                TeacherPostsList(
                    userId: widget.teacher.userId, canManage: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials() {
    final f = widget.teacher.firstName.isNotEmpty
        ? widget.teacher.firstName[0]
        : '';
    final l =
        widget.teacher.lastName.isNotEmpty ? widget.teacher.lastName[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}
