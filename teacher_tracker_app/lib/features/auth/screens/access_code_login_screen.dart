import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../state/auth_controller.dart';

/// Method A onboarding: a young student signs in with the short access code
/// printed on their card — no email or password. The router redirect takes over
/// once the code is accepted.
class AccessCodeLoginScreen extends ConsumerStatefulWidget {
  const AccessCodeLoginScreen({super.key});

  @override
  ConsumerState<AccessCodeLoginScreen> createState() =>
      _AccessCodeLoginScreenState();
}

class _AccessCodeLoginScreenState extends ConsumerState<AccessCodeLoginScreen> {
  final _code = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).loginWithAccessCode(code);
      // Router redirect lands the student in their shell once authenticated.
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(messageForError(e, loc, statusMessages: {
            401: 'That code is not valid. Check the card and try again.',
          })),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassScaffold(
      appBar: AppBar(title: const Text('Enter your code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              float: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.badge_outlined,
                      size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text('Type your access code',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your teacher gave you a card with a short code on it.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _code,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: 8, fontWeight: FontWeight.bold),
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'A3B7Q9',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uppercases access-code input as it is typed (codes are stored uppercase).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
