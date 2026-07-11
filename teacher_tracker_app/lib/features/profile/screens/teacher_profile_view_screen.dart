import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../auth/state/auth_controller.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_cover_header.dart';
import '../widgets/teacher_posts_list.dart';

/// A teacher's profile, opened by tapping an author in the Hub feed: cover,
/// avatar, name, then their posts (pinned first). Read-only — editing your own
/// profile happens on the Profile tab. When you open your own profile here you
/// can still pin/manage your posts.
class TeacherProfileViewScreen extends ConsumerWidget {
  const TeacherProfileViewScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherAsync = ref.watch(teacherProfileProvider(userId));
    final myUserId = ref.watch(currentTeacherProvider)?.userId;
    final isMe = myUserId == userId;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
      ),
      body: teacherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (teacher) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherProfileProvider(userId));
            await ref.read(teacherProfileProvider(userId).future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              ProfileCoverHeader(
                name: teacher.fullName,
                subtitle: isMe ? teacher.email : null,
                initials: _initials(teacher.firstName, teacher.lastName),
                avatarFileId: teacher.avatarFileId,
                coverFileId: teacher.coverFileId,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TeacherPostsList(userId: userId, canManage: isMe),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0] : '';
    final l = last.isNotEmpty ? last[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}
