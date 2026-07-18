import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/state/auth_controller.dart';
import '../state/student_providers.dart';

/// The signed-in student's own profile: name, student number, class count, and
/// sign-out.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    final classesAsync = ref.watch(studentClassesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 24, 20, 40),
        children: [
          Text(loc.navProfile,
              style: tt.headlineMedium?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          GlassCard(
            float: true,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                  child: Text(
                    _initials(student?.firstName, student?.lastName),
                    style: tt.headlineSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),
                Text(student?.fullName ?? loc.stuStudentFallback,
                    style: tt.titleLarge?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
                if ((student?.studentNumber ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(loc.stuStudentNumber(student!.studentNumber),
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.class_outlined, color: cs.primary),
              title: Text(loc.stuEnrolledClasses),
              trailing: Text(
                classesAsync.maybeWhen(
                    data: (c) => c.length.toString(), orElse: () => '—'),
                style: tt.titleMedium?.copyWith(color: cs.onSurface),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(loc.settingsSignOut),
          ),
        ],
      ),
    );
  }

  String _initials(String? first, String? last) {
    final f = (first != null && first.isNotEmpty) ? first[0] : '';
    final l = (last != null && last.isNotEmpty) ? last[0] : '';
    final res = '$f$l'.toUpperCase();
    return res.isEmpty ? '?' : res;
  }
}
