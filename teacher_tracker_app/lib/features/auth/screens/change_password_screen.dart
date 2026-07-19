import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../state/auth_controller.dart';

/// Self-service password change. Two modes:
///  - [forced] (first-login gate): reached via the `/change-password` route when
///    the account must set its own password; no way to back out.
///  - voluntary: pushed from the profile screen; can be dismissed, and pops on
///    success.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final loc = AppLocalizations.of(context)!;
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: _current.text,
            newPassword: _newPassword.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.changePasswordSuccess)),
      );
      // Forced mode: the router releases the gate once state updates, so there's
      // nothing to pop. Voluntary mode: dismiss back to where we came from.
      if (!widget.forced) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(context, e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              float: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.password,
                        size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(loc.changePasswordTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.forced
                          ? loc.changePasswordFirstLoginSubtitle
                          : loc.changePasswordSubtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _current,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.changePasswordCurrentLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          Validators.required(v, message: loc.commonRequired),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _newPassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.changePasswordNewLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (v) => Validators.password(
                        v,
                        requiredMessage: loc.commonRequired,
                        tooShortMessage: loc.commonPasswordTooShort,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: loc.changePasswordConfirmLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: Validators.confirms(
                        _newPassword,
                        message: loc.commonPasswordsDoNotMatch,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(loc.changePasswordSubmit),
                    ),
                    if (widget.forced) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () =>
                                ref.read(authControllerProvider.notifier).logout(),
                        child: Text(loc.settingsSignOut),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _message(BuildContext context, Object e) {
    return messageForError(e, AppLocalizations.of(context)!);
  }
}
