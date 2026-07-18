import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/student.dart';
import '../state/students_providers.dart';
import 'student_profile_screen.dart';
import 'student_form_screen.dart';

/// Student Dashboard — matches the "Student Dashboard" Stitch screen.
/// Glassmorphic card grid with a Quick Access row and search field.
class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(loc.commonError('$e'))),
        data: (students) {
          final filtered = _query.isEmpty
              ? students
              : students
                  .where((s) =>
                      s.fullName
                          .toLowerCase()
                          .contains(_query.toLowerCase()) ||
                      s.studentNumber
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
                  .toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(studentsProvider.future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Top app bar ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _GlassAppBar(cs: cs, tt: tt),
                ),
                // ── Search ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _SearchField(
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
                // ── Quick Access ─────────────────────────────────────────
                if (_query.isEmpty && students.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _QuickAccessRow(
                      students: students.take(5).toList(),
                      onAdd: () => _openForm(context),
                      onTap: (s) => _openProfile(context, s),
                      cs: cs,
                      tt: tt,
                    ),
                  ),
                // ── All students header ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Text(loc.hwTrackerAllStudents,
                            style: tt.titleLarge?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Chip(
                          label: Text(
                            'Class 3B',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.primary),
                          ),
                          backgroundColor:
                              cs.primary.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Student grid ──────────────────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyOrNoMatch(query: _query),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisExtent: 120,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _StudentCard(
                        student: filtered[i],
                        onTap: () => _openProfile(ctx, filtered[i]),
                        onEdit: () => _openEdit(ctx, filtered[i]),
                        cs: cs,
                        tt: tt,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      // FAB to add student
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(loc.dashboardAddStudent),
      ),
    );
  }

  void _openForm(BuildContext ctx) {
    Navigator.of(ctx)
        .push(MaterialPageRoute(builder: (_) => const StudentFormScreen()));
  }

  void _openEdit(BuildContext ctx, Student s) {
    Navigator.of(ctx)
        .push(MaterialPageRoute(builder: (_) => StudentFormScreen(student: s)));
  }

  void _openProfile(BuildContext ctx, Student s) {
    Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => StudentProfileScreen(student: s)));
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget {
  const _GlassAppBar({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.menu, color: cs.primary),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.dashboardAssistant,
                  style: tt.headlineMedium
                      ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
              const Spacer(),
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                child: Icon(Icons.person, color: cs.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.dashboardSearchHint,
              prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              fillColor: Colors.transparent,
              filled: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.students,
    required this.onAdd,
    required this.onTap,
    required this.cs,
    required this.tt,
  });
  final List<Student> students;
  final VoidCallback onAdd;
  final void Function(Student) onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(AppLocalizations.of(context)!.dashboardQuickAccess,
              style: tt.titleLarge
                  ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              ...students.map((s) => _QuickAvatar(
                    name: s.firstName,
                    initials: _initials(s),
                    onTap: () => onTap(s),
                    cs: cs,
                    tt: tt,
                  )),
              _QuickAddButton(onTap: onAdd, cs: cs, tt: tt),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

class _QuickAvatar extends StatelessWidget {
  const _QuickAvatar({
    required this.name,
    required this.initials,
    required this.onTap,
    required this.cs,
    required this.tt,
  });
  final String name;
  final String initials;
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(32),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Text(initials,
                      style: tt.titleLarge?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(name,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onTap, required this.cs, required this.tt});
  final VoidCallback onTap;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(32),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                  child: Icon(Icons.add, color: cs.primary, size: 28)),
            ),
          ),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.commonAdd,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.cs,
    required this.tt,
  });
  final Student student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                child: Text(
                  _initials(),
                  style: tt.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.fullName,
                        style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14,
                            color: cs.primaryContainer),
                        const SizedBox(width: 4),
                        Text(AppLocalizations.of(context)!.attendanceStatusPresent,
                            style: tt.labelSmall
                                ?.copyWith(color: cs.primaryContainer)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _CardActionBtn(
                  icon: Icons.edit_note,
                  onTap: onEdit,
                  cs: cs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardActionBtn(
                  icon: Icons.star_outline,
                  onTap: () {},
                  cs: cs,
                ),
              ),
            ],
          ),
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

class _CardActionBtn extends StatelessWidget {
  const _CardActionBtn({required this.icon, required this.onTap, required this.cs});
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrNoMatch extends StatelessWidget {
  const _EmptyOrNoMatch({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            query.isEmpty ? Icons.group_add_outlined : Icons.search_off,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? loc.studentsEmptyTitle : loc.dashboardNoMatch,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
