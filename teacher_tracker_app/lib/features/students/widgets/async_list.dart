import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final AsyncValue<List<T>> value;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final IconData emptyIcon;
  final String emptyText;

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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                children: [for (final item in items) itemBuilder(item)],
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
          child: FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
