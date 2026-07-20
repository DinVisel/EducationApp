import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/config.dart';
import '../../../core/design.dart';
import '../../../core/location/tr_locations.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/teacher.dart';
import '../../auth/state/auth_controller.dart';

/// Mandatory first-login gate that collects a teacher's demographic profile
/// (Province, District, School type, Education level). Reached via
/// `/profile-setup` whenever [AuthState.needsProfileSetup] is true; there is no
/// way to skip it. Province/District are dependent dropdowns backed by the fixed
/// [trLocationsProvider] list, so the values are canonical and the admin
/// analytics can aggregate them cleanly. On save the session updates, so the
/// router releases the gate automatically.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _province;
  String? _district;
  SchoolType? _schoolType;
  EducationLevel? _educationLevel;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill anything already on the profile (e.g. a partially-filled account).
    final teacher = ref.read(currentTeacherProvider);
    _province = teacher?.city;
    _district = teacher?.district;
    _schoolType = teacher?.schoolType;
    _educationLevel = teacher?.educationLevel;
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final teacher = ref.read(currentTeacherProvider);
    if (teacher == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            teacher.copyWith(
              city: _province,
              district: _district,
              schoolType: _schoolType,
              educationLevel: _educationLevel,
            ),
          );
      // The router releases the gate once the session updates — nothing to pop.
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageForError(e, loc))),
        );
      }
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse(privacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final locations = ref.watch(trLocationsProvider);

    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              float: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: locations.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(messageForError(e, loc),
                      textAlign: TextAlign.center),
                ),
                data: (data) => _buildForm(theme, loc, data),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, AppLocalizations loc, TrLocations data) {
    final districts = data.districtsOf(_province);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.school_outlined,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(loc.profileSetupTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(loc.profileSetupBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xl),
          // Province — resets the district whenever it changes.
          DropdownButtonFormField<String>(
            initialValue: _province,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.settingsCity,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            hint: Text(loc.profileSetupSelect),
            items: [
              for (final name in data.provinceNames)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            validator: (v) => v == null ? loc.commonRequired : null,
            onChanged: (v) => setState(() {
              _province = v;
              _district = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          // District — enabled only after a province is chosen.
          DropdownButtonFormField<String>(
            initialValue: districts.contains(_district) ? _district : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.settingsDistrict,
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            hint: Text(_province == null
                ? loc.profileSetupProvinceHint
                : loc.profileSetupSelect),
            items: [
              for (final name in districts)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            validator: (v) => v == null ? loc.commonRequired : null,
            onChanged: _province == null
                ? null
                : (v) => setState(() => _district = v),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<SchoolType>(
            initialValue: _schoolType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.settingsSchoolType,
              prefixIcon: const Icon(Icons.business_outlined),
            ),
            hint: Text(loc.profileSetupSelect),
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
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<EducationLevel>(
            initialValue: _educationLevel,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: loc.settingsEducationLevel,
              prefixIcon: const Icon(Icons.stairs_outlined),
            ),
            hint: Text(loc.profileSetupSelect),
            items: [
              DropdownMenuItem(
                  value: EducationLevel.primarySchool,
                  child: Text(loc.educationLevelPrimary)),
              DropdownMenuItem(
                  value: EducationLevel.middleSchool,
                  child: Text(loc.educationLevelMiddle)),
              DropdownMenuItem(
                  value: EducationLevel.both, child: Text(loc.educationLevelBoth)),
            ],
            validator: (v) => v == null ? loc.commonRequired : null,
            onChanged: (v) => setState(() => _educationLevel = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ConsentText(onTapPrivacy: _openPrivacy),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(loc.profileSetupContinue),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _submitting
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            child: Text(loc.settingsSignOut),
          ),
        ],
      ),
    );
  }
}

/// KVKK/GDPR consent line with a tappable "Privacy Policy" link inside it.
class _ConsentText extends StatefulWidget {
  const _ConsentText({required this.onTapPrivacy});

  final VoidCallback onTapPrivacy;

  @override
  State<_ConsentText> createState() => _ConsentTextState();
}

class _ConsentTextState extends State<_ConsentText> {
  final TapGestureRecognizer _recognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _recognizer.onTap = widget.onTapPrivacy;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final base = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    // The localized string carries a {privacy} placeholder; we split on the
    // resolved link text so the link is a real, tappable span.
    final linkText = loc.profileSetupPrivacyLink;
    final full = loc.profileSetupConsent(linkText);
    final idx = full.indexOf(linkText);

    return Text.rich(
      TextSpan(
        style: base,
        children: idx < 0
            ? [TextSpan(text: full)]
            : [
                TextSpan(text: full.substring(0, idx)),
                TextSpan(
                  text: linkText,
                  style: base?.copyWith(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _recognizer,
                ),
                TextSpan(text: full.substring(idx + linkText.length)),
              ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
