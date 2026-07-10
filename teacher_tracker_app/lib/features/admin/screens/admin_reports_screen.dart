import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/admin_report.dart';
import '../state/admin_providers.dart';

/// The admin moderation queue: open reports first, with a toggle to review
/// already-resolved ones. Each open report can be dismissed or have its content
/// removed.
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _resolved = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminReportsProvider(_resolved));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports',
                      style: tt.headlineMedium?.copyWith(
                          color: cs.onSurface, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Open')),
                      ButtonSegment(value: true, label: Text('Resolved')),
                    ],
                    selected: {_resolved},
                    onSelectionChanged: (s) =>
                        setState(() => _resolved = s.first),
                  ),
                ],
              ),
            ),
          ),
          ...async.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $e')),
              ),
            ],
            data: (reports) {
              if (reports.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        _resolved ? 'No resolved reports.' : 'No open reports 🎉',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ReportCard(report: reports[i]),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.report});
  final AdminReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final removed = report.targetText == null;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                report.targetType == 'Post'
                    ? Icons.article_outlined
                    : Icons.mode_comment_outlined,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text('${report.targetType} report',
                  style: tt.titleSmall?.copyWith(
                      color: cs.onSurface, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (report.isResolved)
                Text(report.resolution ?? 'Resolved',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              removed
                  ? '[content removed]'
                  : '“${report.targetText}”'
                      '${report.targetAuthorName != null ? '\n— ${report.targetAuthorName}' : ''}',
              style: tt.bodyMedium?.copyWith(
                  color: removed ? cs.onSurfaceVariant : cs.onSurface,
                  fontStyle: removed ? FontStyle.italic : null),
            ),
          ),
          const SizedBox(height: 10),
          Text('Reason: ${report.reason}',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
          const SizedBox(height: 2),
          Text('Reported by ${report.reporterName}',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          if (!report.isResolved) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _act(context, ref, remove: false),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: removed
                      ? null
                      : () => _act(context, ref, remove: true),
                  child: const Text('Remove content'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref,
      {required bool remove}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final actions = ref.read(adminActionsProvider);
      remove
          ? await actions.removeContent(report.id)
          : await actions.dismiss(report.id);
      messenger.showSnackBar(SnackBar(
          content: Text(remove ? 'Content removed' : 'Report dismissed')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }
}
