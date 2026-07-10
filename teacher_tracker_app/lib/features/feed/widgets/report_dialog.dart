import 'package:flutter/material.dart';

/// Prompts for a reason to report [what] ('post'/'comment'); returns null if
/// cancelled or empty. Shared by the feed and comments screens.
Future<String?> showReportDialog(BuildContext context, String what) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text('Report $what'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Why are you reporting this?',
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.pop(d, text.isEmpty ? null : text);
          },
          child: const Text('Report'),
        ),
      ],
    ),
  );
}
