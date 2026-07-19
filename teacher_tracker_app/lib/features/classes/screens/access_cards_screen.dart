import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/onboarding.dart';
import '../data/classrooms_repository.dart';
import '../state/classrooms_providers.dart';

/// Method A onboarding (teacher side): bulk-create access-card students for a
/// class by pasting names, then view/print each student's short code and QR.
class AccessCardsScreen extends ConsumerStatefulWidget {
  const AccessCardsScreen({
    super.key,
    required this.classroomId,
    required this.className,
  });

  final int classroomId;
  final String className;

  @override
  ConsumerState<AccessCardsScreen> createState() => _AccessCardsScreenState();
}

class _AccessCardsScreenState extends ConsumerState<AccessCardsScreen> {
  final _names = TextEditingController();
  bool _busy = false;

  // Cards keyed by student id. Freshly created/rotated cards carry their raw QR
  // token; listed cards (loaded on open) only have the typed code.
  final Map<int, AccessCard> _cards = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _names.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final existing = await ref
          .read(classroomsRepositoryProvider)
          .getAccessCards(widget.classroomId);
      setState(() {
        for (final c in existing) {
          _cards[c.studentId] = c;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(messageForError(e, AppLocalizations.of(context)!));
      }
    }
  }

  Future<void> _generate() async {
    final names = _names.text
        .split('\n')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      _snack('Enter at least one student name (one per line).');
      return;
    }
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(classroomsRepositoryProvider)
          .createAccessCards(widget.classroomId, names);
      setState(() {
        for (final c in created) {
          _cards[c.studentId] = c;
        }
        _names.clear();
      });
      // The roster changed → refresh the class detail.
      ref.invalidate(classroomDetailProvider(widget.classroomId));
      if (mounted) _snack('Created ${created.length} access card(s).');
    } catch (e) {
      if (mounted) _snack(messageForError(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rotate(int studentId) async {
    setState(() => _busy = true);
    try {
      final card = await ref
          .read(classroomsRepositoryProvider)
          .rotateAccessCard(widget.classroomId, studentId);
      setState(() => _cards[studentId] = card);
      if (mounted) _snack('New code generated.');
    } catch (e) {
      if (mounted) _snack(messageForError(e, AppLocalizations.of(context)!));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = _cards.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return GlassScaffold(
      appBar: AppBar(title: Text('Access cards · ${widget.className}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add students', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Paste or type one name per line. Each student gets a '
                        'code and QR they can log in with — no email needed.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _names,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Ada Lovelace\nAlan Turing\nGrace Hopper',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: _busy ? null : _generate,
                        icon: const Icon(Icons.badge_outlined),
                        label: const Text('Generate cards'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('No access-card students yet.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  )
                else
                  ...cards.map((c) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _CardTile(
                          card: c,
                          busy: _busy,
                          onRotate: () => _rotate(c.studentId),
                        ),
                      )),
              ],
            ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.busy,
    required this.onRotate,
  });

  final AccessCard card;
  final bool busy;
  final VoidCallback onRotate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The QR encodes the long secret when we have it (fresh/rotated card),
    // otherwise falls back to the typed code so a printout is still scannable-ish.
    final qrData = card.qrToken ?? card.accessCode;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.fullName, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: qrData,
                  size: 96,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code', style: theme.textTheme.labelSmall),
                    SelectableText(
                      card.accessCode,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, letterSpacing: 4),
                    ),
                    if (card.qrToken == null)
                      Text(
                        'Rotate to regenerate a scannable QR.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: card.accessCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied.')));
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
              ),
              TextButton.icon(
                onPressed: () => Share.share(
                    '${card.fullName}, log in with access code ${card.accessCode}.'),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
              TextButton.icon(
                onPressed: busy ? null : onRotate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Rotate'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
