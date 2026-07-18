import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Prompts for a reason to report something; returns null if cancelled or
/// empty. [title] is the already-localized dialog title (e.g. "Report post").
/// Shared by the feed and comments screens.
Future<String?> showReportDialog(BuildContext context, String title) {
  final controller = TextEditingController();
  final loc = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: loc.reportReasonLabel,
          hintText: loc.reportReasonHint,
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(d), child: Text(loc.commonCancel)),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.pop(d, text.isEmpty ? null : text);
          },
          child: Text(loc.commonReport),
        ),
      ],
    ),
  );
}
