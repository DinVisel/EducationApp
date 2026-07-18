import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design.dart';
import '../../../core/onboarding/onboarding_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../classes/screens/classes_list_screen.dart';
import '../../classes/state/classrooms_providers.dart';
import '../../students/screens/student_form_screen.dart';
import '../../students/state/students_providers.dart';

/// First-login walkthrough for a new teacher: welcome → create a class → add a
/// student → finish. Each step can be skipped; finishing (or skipping) marks
/// onboarding complete via [onboardingControllerProvider] so it never reappears.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _stepCount = 4;
  int _step = 0;

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _createClass() async {
    await createClass(context, ref);
    if (ref.read(classroomsProvider).value?.isNotEmpty ?? false) _next();
  }

  Future<void> _addStudent() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StudentFormScreen()),
    );
    if (ref.read(studentsProvider).value?.isNotEmpty ?? false) _next();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LiquidProgressBar(value: (_step + 1) / _stepCount),
                  const SizedBox(height: AppSpacing.xl),
                  _buildStep(theme, loc),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _finish,
                    child: Text(loc.onboardingSkip),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme, AppLocalizations loc) {
    switch (_step) {
      case 0:
        return _Step(
          icon: Icons.waving_hand_outlined,
          title: loc.onboardingWelcomeTitle,
          body: loc.onboardingWelcomeBody,
          buttonLabel: loc.onboardingGetStarted,
          onPressed: _next,
          theme: theme,
        );
      case 1:
        return _Step(
          icon: Icons.class_outlined,
          title: loc.onboardingClassTitle,
          body: loc.onboardingClassBody,
          buttonLabel: loc.onboardingCreateClass,
          onPressed: _createClass,
          theme: theme,
        );
      case 2:
        return _Step(
          icon: Icons.person_add_alt_1_outlined,
          title: loc.onboardingStudentTitle,
          body: loc.onboardingStudentBody,
          buttonLabel: loc.onboardingAddStudent,
          onPressed: _addStudent,
          theme: theme,
        );
      default:
        return _Step(
          icon: Icons.celebration_outlined,
          title: loc.onboardingDoneTitle,
          body: loc.onboardingDoneBody,
          buttonLabel: loc.onboardingGoHub,
          onPressed: _finish,
          theme: theme,
        );
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 72, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(title,
            textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: onPressed,
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
