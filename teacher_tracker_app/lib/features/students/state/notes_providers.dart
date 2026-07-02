import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/tracking_note.dart';
import '../data/notes_repository.dart';

/// Tracking notes for one student, keyed by studentId.
class NotesNotifier extends AsyncNotifier<List<TrackingNote>> {
  NotesNotifier(this.studentId);

  final int studentId;

  @override
  Future<List<TrackingNote>> build() =>
      ref.read(notesRepositoryProvider).getForStudent(studentId);

  Future<void> _reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notesRepositoryProvider).getForStudent(studentId),
    );
  }

  Future<void> add({required String category, required String content}) async {
    await ref
        .read(notesRepositoryProvider)
        .create(studentId, category: category, content: content);
    await _reload();
  }

  Future<void> remove(int id) async {
    await ref.read(notesRepositoryProvider).delete(studentId, id);
    await _reload();
  }
}

final notesProvider =
    AsyncNotifierProvider.family<NotesNotifier, List<TrackingNote>, int>(
  NotesNotifier.new,
);
