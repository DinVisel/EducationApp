import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      if (mounted) setState(() => _submitted = true);
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
              child: _submitted
                  ? _buildConfirmation(theme, loc)
                  : _buildForm(theme, loc),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, AppLocalizations loc) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(loc.forgotPasswordTitle,
              textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            loc.forgotPasswordSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: loc.forgotPasswordEmailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            onFieldSubmitted: (_) => _submit(),
            validator: (v) => Validators.email(
              v,
              requiredMessage: loc.commonRequired,
              invalidMessage: loc.commonInvalidEmail,
            ),
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
                : Text(loc.forgotPasswordSubmit),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _submitting ? null : () => context.go('/login'),
            child: Text(loc.forgotPasswordBackToSignIn),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(ThemeData theme, AppLocalizations loc) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(loc.forgotPasswordConfirmTitle,
            textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          loc.forgotPasswordConfirmBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => context.push('/reset-password'),
          child: Text(loc.forgotPasswordHaveCode),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(loc.forgotPasswordBackToSignIn),
        ),
      ],
    );
  }

  String _message(BuildContext context, Object e) {
    final loc = AppLocalizations.of(context)!;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is String && data.isNotEmpty) return data;
      return loc.commonNetworkError;
    }
    return loc.commonSomethingWentWrong;
  }
}
