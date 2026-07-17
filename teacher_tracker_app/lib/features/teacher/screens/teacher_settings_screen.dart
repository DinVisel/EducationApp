import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/teacher.dart';
import '../../auth/state/auth_controller.dart';

/// Account settings for the signed-in teacher: editable name/email and
/// sign-out. Reached via the gear icon on [TeacherProfileScreen], which keeps
/// only visual identity (cover/avatar) and the public post history.
class TeacherSettingsScreen extends ConsumerWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(currentTeacherProvider);
    final loc = AppLocalizations.of(context)!;

    return GlassScaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: teacher == null
          ? const Center(child: CircularProgressIndicator())
          : _SettingsForm(teacher: teacher),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.teacher});

  final Teacher teacher;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.teacher.firstName);
    _lastName = TextEditingController(text: widget.teacher.lastName);
    _email = TextEditingController(text: widget.teacher.email);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            widget.teacher.copyWith(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.settingsProfileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.settingsSaveFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.settingsSignOutConfirmTitle),
        content: Text(loc.settingsSignOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.settingsSignOut),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 8, 20, 40),
      children: [
        Text(loc.settingsAccount,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GlassCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: loc.settingsFirstName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? loc.commonRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: loc.settingsLastName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? loc.commonRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: loc.settingsEmail),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return loc.commonRequired;
                    if (!value.contains('@')) return loc.commonInvalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(loc.settingsSaveChanges),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(loc.settingsLanguage,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const _LanguagePicker(),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout),
          label: Text(loc.settingsSignOut),
        ),
      ],
    );
  }
}

/// Lets the teacher pick English or Türkçe, or follow the system locale.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final locale = ref.watch(localeControllerProvider).value;

    return GlassCard(
      child: Column(
        children: [
          RadioListTile<String?>(
            title: Text(loc.settingsLanguageEnglish),
            value: 'en',
            groupValue: locale?.languageCode,
            onChanged: (v) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(const Locale('en')),
          ),
          RadioListTile<String?>(
            title: Text(loc.settingsLanguageTurkish),
            value: 'tr',
            groupValue: locale?.languageCode,
            onChanged: (v) => ref
                .read(localeControllerProvider.notifier)
                .setLocale(const Locale('tr')),
          ),
        ],
      ),
    );
  }
}
