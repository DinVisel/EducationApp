import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/design.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/teacher.dart';
import '../../auth/state/auth_controller.dart';

/// Mandatory first-login gate that collects a teacher's demographic profile
/// (City, District, School type, Education level). Reached via `/profile-setup`
/// whenever [AuthState.needsProfileSetup] is true; there is no way to skip it.
/// On save the session updates, so the router releases the gate automatically.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _city = TextEditingController();
  final _district = TextEditingController();
  SchoolType? _schoolType;
  EducationLevel? _educationLevel;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill anything already on the profile (e.g. a partially-filled account).
    final teacher = ref.read(currentTeacherProvider);
    _city.text = teacher?.city ?? '';
    _district.text = teacher?.district ?? '';
    _schoolType = teacher?.schoolType;
    _educationLevel = teacher?.educationLevel;
  }

  @override
  void dispose() {
    _city.dispose();
    _district.dispose();
    super.dispose();
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
              city: _city.text.trim(),
              district: _district.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return GlassScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GlassCard(
              float: true,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: loc.settingsCity,
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      validator: (v) =>
                          Validators.required(v, message: loc.commonRequired),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _district,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: loc.settingsDistrict,
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                      validator: (v) =>
                          Validators.required(v, message: loc.commonRequired),
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
                            value: SchoolType.state,
                            child: Text(loc.schoolTypeState)),
                        DropdownMenuItem(
                            value: SchoolType.private,
                            child: Text(loc.schoolTypePrivate)),
                        DropdownMenuItem(
                            value: SchoolType.other,
                            child: Text(loc.schoolTypeOther)),
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
                            value: EducationLevel.both,
                            child: Text(loc.educationLevelBoth)),
                      ],
                      validator: (v) => v == null ? loc.commonRequired : null,
                      onChanged: (v) => setState(() => _educationLevel = v),
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
                          : Text(loc.profileSetupContinue),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () =>
                              ref.read(authControllerProvider.notifier).logout(),
                      child: Text(loc.settingsSignOut),
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
}
