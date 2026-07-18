import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

/// Renders an [AsyncValue] list with shared loading / error / empty / data
/// handling and pull-to-refresh. Used by the student detail tabs.
class AsyncList<T> extends StatelessWidget {
  const AsyncList({
    super.key,
    required this.value,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onRetry,
    required this.emptyIcon,
    required this.emptyText,
    this.scrollController,
    this.loadingMore = false,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final IconData emptyIcon;
  final String emptyText;

  /// Attach to drive "load more" near the bottom; omit for non-paginated lists.
  final ScrollController? scrollController;

  /// Shows a trailing spinner row while the next page is loading.
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorState(message: '$err', onRetry: onRetry),
      data: (items) => RefreshIndicator(
        onRefresh: onRefresh,
        child: items.isEmpty
            ? _EmptyState(icon: emptyIcon, text: emptyText)
            : ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                children: [
                  for (final item in items) itemBuilder(item),
                  if (loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: Theme.of(context).hintColor),
        const SizedBox(height: 12),
        Center(child: Text(text)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
        Center(
          child: FilledButton.tonal(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.commonRetry)),
        ),
      ],
    );
  }
}
