import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../models/student.dart';
import '../auth/state/auth_controller.dart';
import '../classes/state/classrooms_providers.dart';
import '../students/screens/student_form_screen.dart';
import '../students/screens/student_profile_screen.dart';
import '../students/state/students_providers.dart';

/// Home landing page — the first tab of the app shell. Greets the teacher,
/// surfaces at-a-glance stats, quick actions, and a shortcut to recent
/// students. Tapping an action jumps to the matching bottom-nav tab.
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key, required this.onNavigate});

  /// Switches the app shell to the tab at [index].
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final teacher = ref.watch(currentTeacherProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final classroomsAsync = ref.watch(classroomsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _Greeting(
                name: teacher?.firstName ?? 'Teacher',
                cs: cs,
                tt: tt,
              ),
            ),
            // ── Overview stats ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.groups,
                        label: 'Students',
                        value: studentsAsync.maybeWhen(
                          data: (s) => s.length.toString(),
                          orElse: () => '—',
                        ),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.class_,
                        label: 'Classes',
                        value: classroomsAsync.maybeWhen(
                          data: (c) => c.length.toString(),
                          orElse: () => '—',
                        ),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Quick actions ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Quick Actions', cs: cs, tt: tt),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.groups_outlined,
                        label: 'Students',
                        onTap: () => onNavigate(1),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.class_outlined,
                        label: 'Classes',
                        onTap: () => onNavigate(2),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.menu_book_outlined,
                        label: 'Homework',
                        onTap: () => onNavigate(3),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.auto_stories_outlined,
                        label: 'Reading',
                        onTap: () => onNavigate(4),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Recent students ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Row(
                children: [
                  _SectionHeader(title: 'Recent Students', cs: cs, tt: tt),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 24),
                    child: TextButton(
                      onPressed: () => onNavigate(1),
                      child: const Text('See all'),
                    ),
                  ),
                ],
              ),
            ),
            studentsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error: $e',
                      style: tt.bodyMedium?.copyWith(color: cs.error)),
                ),
              ),
              data: (students) {
                if (students.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyStudents(
                      onAdd: () => _openForm(context),
                      cs: cs,
                      tt: tt,
                    ),
                  );
                }
                final recent = students.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: recent.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _StudentRow(
                      student: recent[i],
                      onTap: () => _openProfile(ctx, recent[i]),
                      cs: cs,
                      tt: tt,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext ctx) {
    Navigator.of(ctx)
        .push(MaterialPageRoute(builder: (_) => const StudentFormScreen()));
  }

  void _openProfile(BuildContext ctx, Student s) {
    Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => StudentProfileScreen(student: s)));
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.cs, required this.tt});
  final String name;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 24, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(name,
                    style: tt.headlineMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
            child: Icon(Icons.person, color: cs.primary, size: 26),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      float: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 28),
          const SizedBox(height: 12),
          Text(value,
              style: tt.headlineMedium?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w700)),
          Text(label,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.cs, required this.tt});
  final String title;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(title,
          style: tt.titleLarge
              ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: cs.primary, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: tt.labelMedium?.copyWith(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.onTap,
    required this.cs,
    required this.tt,
  });
  final Student student;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
            child: Text(_initials(),
                style: tt.labelLarge?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('No. ${student.studentNumber}',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  String _initials() {
    final f = student.firstName.isNotEmpty ? student.firstName[0] : '';
    final l = student.lastName.isNotEmpty ? student.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents({required this.onAdd, required this.cs, required this.tt});
  final VoidCallback onAdd;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.group_add_outlined,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No students yet',
                style: tt.titleMedium?.copyWith(color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('Add your first student to get started.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }
}
