import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/teacher.dart';
import '../../auth/state/auth_controller.dart';
import '../../files/data/files_repository.dart';
import '../../files/image_processing.dart';
import '../../files/mime.dart';
import '../../profile/widgets/profile_cover_header.dart';
import '../../profile/widgets/teacher_posts_list.dart';
import 'teacher_settings_screen.dart';

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
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeacherSettingsScreen()),
            ),
          ),
        ],
      ),
      body: teacher == null
          ? const Center(child: CircularProgressIndicator())
          : _ProfileBody(teacher: teacher),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.teacher});

  final Teacher teacher;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _uploadingImage = false;

  /// Pick an image, crop it (square for the avatar, wide for the cover),
  /// compress, upload to R2, then persist it as the avatar or cover.
  Future<void> _changeImage({required bool cover}) async {
    final loc = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.first;
    var bytes = f.bytes;
    var fileName = f.name;
    var contentType = mimeForFileName(f.name);

    // Crop + compress when we have a real path (mobile). Fall back to the raw
    // bytes on platforms where file_picker doesn't expose a path (web/desktop).
    if (f.path != null) {
      final processed = await cropAndCompress(
        path: f.path!,
        originalName: f.name,
        ratioX: cover ? 16 : 1,
        ratioY: cover ? 9 : 1,
        toolbarTitle: loc.imageCropperTitle,
      );
      if (processed == null) return; // user cancelled the crop
      bytes = processed.bytes;
      fileName = processed.fileName;
      contentType = processed.contentType;
    }
    if (bytes == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingImage = true);
    try {
      final uploaded = await ref.read(filesRepositoryProvider).uploadDirect(
            bytes: bytes,
            fileName: fileName,
            contentType: contentType,
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
    return ListView(
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Your posts',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              TeacherPostsList(userId: widget.teacher.userId, canManage: true),
            ],
          ),
        ),
      ],
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
