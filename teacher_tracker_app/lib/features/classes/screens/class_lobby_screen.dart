import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../data/classrooms_repository.dart';
import '../state/classrooms_providers.dart';

/// Method B onboarding (teacher side): the Waiting Lobby. Lists students who
/// submitted this class's code and are awaiting approval; the teacher accepts or
/// declines each. Approval enrolls the student.
class ClassLobbyScreen extends ConsumerWidget {
  const ClassLobbyScreen({
    super.key,
    required this.classroomId,
    required this.className,
  });

  final int classroomId;
  final String className;

  Future<void> _decide(
      BuildContext context, WidgetRef ref, int requestId, bool approve) async {
    final repo = ref.read(classroomsRepositoryProvider);
    try {
      if (approve) {
        await repo.approveJoinRequest(classroomId, requestId);
      } else {
        await repo.rejectJoinRequest(classroomId, requestId);
      }
      ref.invalidate(classLobbyProvider(classroomId));
      ref.invalidate(classroomDetailProvider(classroomId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approve ? 'Student approved.' : 'Request declined.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(messageForError(e, AppLocalizations.of(context)!))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lobby = ref.watch(classLobbyProvider(classroomId));

    return GlassScaffold(
      appBar: AppBar(title: Text('Waiting lobby · $className')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(classLobbyProvider(classroomId)),
        child: lobby.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(messageForError(e, AppLocalizations.of(context)!),
                  textAlign: TextAlign.center),
            ),
          ]),
          data: (entries) {
            if (entries.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 120),
                Icon(Icons.inbox_outlined,
                    size: 64, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: AppSpacing.sm),
                Text('No pending requests',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Share the class code so students can request to join.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.fullName,
                                  style: theme.textTheme.titleMedium),
                              if (e.email != null && e.email!.isNotEmpty)
                                Text(e.email!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Approve',
                          onPressed: () =>
                              _decide(context, ref, e.requestId, true),
                          icon: const Icon(Icons.check),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: 'Decline',
                          onPressed: () =>
                              _decide(context, ref, e.requestId, false),
                          icon: Icon(Icons.close,
                              color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
