import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/onboarding.dart';
import '../data/student_module_repository.dart';
import '../state/student_providers.dart';

/// Method B onboarding (student side): an older student enters a class code to
/// request to join. They land in the Waiting Lobby until the teacher approves;
/// this screen also shows the status of their past requests.
class JoinClassScreen extends ConsumerStatefulWidget {
  const JoinClassScreen({super.key});

  @override
  ConsumerState<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends ConsumerState<JoinClassScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(studentModuleRepositoryProvider).requestToJoin(code);
      _code.clear();
      ref.invalidate(studentJoinRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Request sent! Wait for your teacher to approve.')));
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(messageForError(e, loc, statusMessages: {
            404: 'No class matches that code.',
            409: 'You already requested to join, or are already in this class.',
          })),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(int requestId) async {
    try {
      await ref.read(studentModuleRepositoryProvider).cancelRequest(requestId);
      ref.invalidate(studentJoinRequestsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(messageForError(e, AppLocalizations.of(context)!))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requests = ref.watch(studentJoinRequestsProvider);

    return GlassScaffold(
      appBar: AppBar(title: const Text('Join a class')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Enter class code', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ask your teacher for the class code (like MAT101).',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    _UpperCase(),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  style: theme.textTheme.titleLarge
                      ?.copyWith(letterSpacing: 4, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: 'MAT101',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('Request to join'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Your requests', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          requests.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(
                messageForError(e, AppLocalizations.of(context)!)),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('No requests yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                );
              }
              return Column(
                children: list
                    .map((r) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _RequestTile(
                              request: r,
                              onCancel:
                                  r.isPending ? () => _cancel(r.id) : null),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, this.onCancel});

  final ClassJoinRequest request;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, label) = switch (request.status) {
      'Approved' => (Colors.green, Icons.check_circle, 'Approved'),
      'Rejected' => (theme.colorScheme.error, Icons.cancel, 'Declined'),
      _ => (theme.colorScheme.primary, Icons.hourglass_top, 'Pending'),
    };

    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.className, style: theme.textTheme.titleMedium),
                Text('$label · ${request.teacherName}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (onCancel != null)
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
