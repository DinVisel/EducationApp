import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../core/haptics/haptic_controller.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/location/tr_locations.dart';
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
  String? _province;
  String? _district;
  SchoolType? _schoolType;
  EducationLevel? _educationLevel;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.teacher.firstName);
    _lastName = TextEditingController(text: widget.teacher.lastName);
    _email = TextEditingController(text: widget.teacher.email);
    _province = widget.teacher.city;
    _district = widget.teacher.district;
    _schoolType = widget.teacher.schoolType;
    _educationLevel = widget.teacher.educationLevel;
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
    final haptics = ref.read(hapticServiceProvider);
    if (!_formKey.currentState!.validate()) {
      haptics.error();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            widget.teacher.copyWith(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              city: _province,
              district: _district,
              schoolType: _schoolType,
              educationLevel: _educationLevel,
            ),
          );
      if (mounted) {
        haptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.settingsProfileSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        haptics.error();
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
        Text(loc.settingsTeachingProfile,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(loc.settingsTeachingProfileHint,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _LocationFields(
                province: _province,
                district: _district,
                onProvinceChanged: (v) => setState(() {
                  _province = v;
                  _district = null;
                }),
                onDistrictChanged: (v) => setState(() => _district = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SchoolType>(
                initialValue: _schoolType,
                isExpanded: true,
                decoration: InputDecoration(labelText: loc.settingsSchoolType),
                items: [
                  DropdownMenuItem(
                      value: SchoolType.state, child: Text(loc.schoolTypeState)),
                  DropdownMenuItem(
                      value: SchoolType.private, child: Text(loc.schoolTypePrivate)),
                  DropdownMenuItem(
                      value: SchoolType.other, child: Text(loc.schoolTypeOther)),
                ],
                validator: (v) => v == null ? loc.commonRequired : null,
                onChanged: (v) => setState(() => _schoolType = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EducationLevel>(
                initialValue: _educationLevel,
                isExpanded: true,
                decoration:
                    InputDecoration(labelText: loc.settingsEducationLevel),
                items: [
                  DropdownMenuItem(
                      value: EducationLevel.primarySchool,
                      child: Text(loc.educationLevelPrimary)),
                  DropdownMenuItem(
                      value: EducationLevel.middleSchool,
                      child: Text(loc.educationLevelMiddle)),
                  DropdownMenuItem(
                      value: EducationLevel.both,
                      child: Text(loc.educationLevelBoth)),
                ],
                validator: (v) => v == null ? loc.commonRequired : null,
                onChanged: (v) => setState(() => _educationLevel = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(loc.settingsLanguage,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const _LanguagePicker(),
        const SizedBox(height: 24),
        Text(loc.settingsAppearance,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const _ThemePicker(),
        const SizedBox(height: 24),
        Text(loc.settingsHaptics,
            style: tt.titleMedium
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const _HapticsToggle(),
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

/// Dependent Province → District dropdowns backed by [trLocationsProvider], so
/// the saved values stay canonical (matching the profile-setup gate and keeping
/// the admin analytics clean). While the bundled dataset loads, the teacher's
/// current values remain selectable so they're never dropped.
class _LocationFields extends ConsumerWidget {
  const _LocationFields({
    required this.province,
    required this.district,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
  });

  final String? province;
  final String? district;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onDistrictChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final data = ref.watch(trLocationsProvider).value;

    final provinceNames = data?.provinceNames ?? [?province];
    final districts = data?.districtsOf(province) ?? [?district];

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: province,
          isExpanded: true,
          decoration: InputDecoration(labelText: loc.settingsCity),
          items: [
            for (final n in provinceNames)
              DropdownMenuItem(value: n, child: Text(n)),
          ],
          validator: (v) => v == null ? loc.commonRequired : null,
          onChanged: onProvinceChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: districts.contains(district) ? district : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: loc.settingsDistrict),
          items: [
            for (final n in districts)
              DropdownMenuItem(value: n, child: Text(n)),
          ],
          validator: (v) => v == null ? loc.commonRequired : null,
          onChanged: province == null ? null : onDistrictChanged,
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

/// Lets the teacher pick a system / light / dark theme.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final mode = ref.watch(themeControllerProvider).value ?? ThemeMode.system;

    void set(ThemeMode m) =>
        ref.read(themeControllerProvider.notifier).setMode(m);

    return GlassCard(
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: Text(loc.settingsThemeSystem),
            value: ThemeMode.system,
            groupValue: mode,
            onChanged: (v) => set(ThemeMode.system),
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.settingsThemeLight),
            value: ThemeMode.light,
            groupValue: mode,
            onChanged: (v) => set(ThemeMode.light),
          ),
          RadioListTile<ThemeMode>(
            title: Text(loc.settingsThemeDark),
            value: ThemeMode.dark,
            groupValue: mode,
            onChanged: (v) => set(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

/// Toggle for enabling/disabling haptic feedback across the app.
class _HapticsToggle extends ConsumerWidget {
  const _HapticsToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final enabled = ref.watch(hapticControllerProvider).value ?? true;

    return GlassCard(
      child: SwitchListTile.adaptive(
        title: Text(loc.settingsHapticsToggle),
        secondary: const Icon(Icons.vibration),
        value: enabled,
        onChanged: (v) {
          ref.read(hapticControllerProvider.notifier).setEnabled(v);
          if (v) ref.read(hapticServiceProvider).tap();
        },
      ),
    );
  }
}
