import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../state/auth_controller.dart';
import 'access_code_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text, _password.text);
      // Router redirect takes over once authenticated.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_message(context, e))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } on RoleSelectionRequired catch (pending) {
      await _completeWithRole(pending);
    } on GoogleSignInException catch (e) {
      // User dismissed the sheet — not an error worth surfacing.
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (mounted) _showError(e);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithApple();
    } on RoleSelectionRequired catch (pending) {
      await _completeWithRole(pending);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (mounted) _showError(e);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // A new social account must choose Teacher or Student; then we re-submit the
  // same verified token with that role.
  Future<void> _completeWithRole(RoleSelectionRequired pending) async {
    if (!mounted) return;
    final role = await _pickRole();
    if (role == null || !mounted) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeSocialSignup(pending, role);
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  Future<String?> _pickRole() {
    final loc = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(loc.rolePickerTitle,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: Text(loc.roleTeacher),
              onTap: () => Navigator.of(ctx).pop('Teacher'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(loc.roleStudent),
              onTap: () => Navigator.of(ctx).pop('Student'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_message(context, e))));
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
                    Icon(Icons.school,
                        size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(loc.loginTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(loc.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: loc.loginEmailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) => Validators.email(
                        v,
                        requiredMessage: loc.commonRequired,
                        invalidMessage: loc.commonInvalidEmail,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: loc.loginPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          Validators.required(v, message: loc.commonRequired),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => context.push('/forgot-password'),
                        child: Text(loc.loginForgotPassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(loc.loginSignIn),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                          child: Text(loc.commonOr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(loc.loginContinueWithGoogle),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SignInWithAppleButton(
                      onPressed: _submitting ? () {} : _signInWithApple,
                      style: theme.brightness == Brightness.dark
                          ? SignInWithAppleButtonStyle.white
                          : SignInWithAppleButtonStyle.black,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed:
                          _submitting ? null : () => context.push('/register'),
                      child: Text(loc.loginNoAccount),
                    ),
                    TextButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const AccessCodeLoginScreen(),
                              )),
                      icon: const Icon(Icons.badge_outlined, size: 18),
                      label: const Text('I have an access code'),
                    ),
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
    final loc = AppLocalizations.of(context)!;
    return messageForError(e, loc,
        statusMessages: {401: loc.loginInvalidCredentials});
  }
}
