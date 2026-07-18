import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/student.dart';
import '../data/student_account_repository.dart';
import '../state/notes_providers.dart';
import '../state/students_providers.dart';
import 'student_form_screen.dart';
import 'tabs/books_tab.dart';
import 'tabs/homework_tab.dart';

/// Student Profile screen — matches the "Student Profile" Stitch screen.
/// Glassmorphic hero card, personal info, recent activity, parent contacts,
/// and sticky notes. Tabs for Homework and Books sit below.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(studentsProvider).maybeWhen(
          data: (list) =>
              list.firstWhere((s) => s.id == student.id, orElse: () => student),
          orElse: () => student,
        );
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _ProfileAppBar(student: current, cs: cs, tt: tt)),
          SliverToBoxAdapter(child: _HeroCard(student: current, cs: cs, tt: tt)),
          SliverToBoxAdapter(child: _PersonalInfoCard(student: current, cs: cs, tt: tt)),
          SliverToBoxAdapter(child: _AccountCard(student: current, cs: cs, tt: tt)),
          SliverToBoxAdapter(child: _RecentActivityCard(cs: cs, tt: tt)),
          SliverToBoxAdapter(child: _ParentContactsCard(student: current, cs: cs, tt: tt)),
          SliverToBoxAdapter(child: _NotesCardSection(student: current, cs: cs, tt: tt)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _glassTabBar(cs, tt, loc),
              Expanded(
                child: TabBarView(
                  children: [
                    HomeworkTab(studentId: current.id),
                    BooksTab(studentId: current.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassTabBar(ColorScheme cs, TextTheme tt, AppLocalizations loc) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: cs.surface.withValues(alpha: 0.5),
          child: TabBar(
            tabs: [
              Tab(
                  icon: const Icon(Icons.assignment_outlined),
                  text: loc.classTabHomework),
              Tab(
                  icon: const Icon(Icons.menu_book_outlined),
                  text: loc.booksTabTitle),
            ],
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar(
      {required this.student, required this.cs, required this.tt});
  final Student student;
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
            left: 8,
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
              IconButton(
                icon: Icon(Icons.arrow_back, color: cs.primary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(AppLocalizations.of(context)!.studentProfileTitle,
                  style: tt.headlineMedium?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        float: true,
        child: Stack(
          children: [
            // Decorative teal blob in the background
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppPalette.primaryFixed.withValues(alpha: 0.5),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          cs.primaryContainer.withValues(alpha: 0.4),
                      child: Text(
                        _initials(student),
                        style: tt.displayLarge?.copyWith(
                            color: cs.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: cs.surface, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star,
                                size: 12,
                                color: cs.onSecondaryContainer),
                            const SizedBox(width: 2),
                            Text('High Achiever',
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onSecondaryContainer,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: tt.headlineMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grade 3-B • Room 104',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Tag('Reading: Level L', cs.primary),
                          _Tag('Math: Blue', cs.tertiary),
                          if (student.notes != null && student.notes!.isNotEmpty)
                            _Tag(student.notes!, cs.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        StudentFormScreen(student: student)),
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(AppLocalizations.of(context)!.commonEdit),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 36)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.print, size: 16),
                              label: Text(
                                  AppLocalizations.of(context)!.studentProfileReport),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 36)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(Student s) {
    final f = s.firstName.isNotEmpty ? s.firstName[0] : '';
    final l = s.lastName.isNotEmpty ? s.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontSize: 11)),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: Icons.person_outline,
                title: loc.studentProfilePersonalInfo,
                cs: cs,
                tt: tt),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoItem(
                    label: loc.studentProfileStudentId,
                    value: student.studentNumber.isEmpty
                        ? loc.commonNotAvailable
                        : '#${student.studentNumber}',
                    cs: cs,
                    tt: tt),
                const SizedBox(width: 16),
                _InfoItem(
                    label: loc.studentProfileGrade, value: '3-B', cs: cs, tt: tt),
              ],
            ),
            const SizedBox(height: 12),
            if (student.firstName.isNotEmpty)
              _InfoItem(
                  label: loc.studentProfileFullName,
                  value: student.fullName,
                  cs: cs,
                  tt: tt),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(
      {required this.label,
      required this.value,
      required this.cs,
      required this.tt});
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant, letterSpacing: 0.06)),
          const SizedBox(height: 2),
          Text(value, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.cs, required this.tt});
  final ColorScheme cs;
  final TextTheme tt;

  static final _items = [
    (Icons.auto_stories, 'Finished reading "The Magic Treehouse"',
        'Today, 10:30 AM'),
    (Icons.calculate, 'Scored 95% on Fractions Quiz', 'Yesterday, 1:15 PM'),
    (Icons.mood, "Awarded 'Helper of the Week'", 'Oct 12, 9:00 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: Icons.history,
                title: AppLocalizations.of(context)!.studentProfileRecentActivity,
                cs: cs,
                tt: tt),
            const SizedBox(height: 8),
            ..._items.map((item) => _ActivityItem(
                  icon: item.$1,
                  text: item.$2,
                  time: item.$3,
                  cs: cs,
                  tt: tt,
                )),
            TextButton(
              onPressed: () {},
              child: Text(
                  AppLocalizations.of(context)!.studentProfileViewHistory),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem(
      {required this.icon,
      required this.text,
      required this.time,
      required this.cs,
      required this.tt});
  final IconData icon;
  final String text;
  final String time;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                Text(time,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentContactsCard extends StatelessWidget {
  const _ParentContactsCard(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
                icon: Icons.family_restroom,
                title: AppLocalizations.of(context)!.studentProfileParentContacts,
                cs: cs,
                tt: tt),
            const SizedBox(height: 12),
            _ContactItem(
                initial: 'P',
                name: 'Primary Guardian',
                role: 'Mother (Primary)',
                cs: cs,
                tt: tt),
            const SizedBox(height: 8),
            _ContactItem(
                initial: 'G',
                name: 'Guardian 2',
                role: 'Father',
                cs: cs,
                tt: tt),
          ],
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem(
      {required this.initial,
      required this.name,
      required this.role,
      required this.cs,
      required this.tt});
  final String initial;
  final String name;
  final String role;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary.withValues(alpha: 0.2),
            child: Text(initial,
                style: tt.labelLarge?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w600)),
                Text(role,
                    style:
                        tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Row(
            children: [
              _ContactBtn(icon: Icons.call, cs: cs),
              const SizedBox(width: 8),
              _ContactBtn(icon: Icons.chat_bubble_outline, cs: cs),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  const _ContactBtn({required this.icon, required this.cs});
  final IconData icon;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, size: 16, color: cs.primary),
      ),
    );
  }
}

class _NotesCardSection extends ConsumerWidget {
  const _NotesCardSection(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final notesAsync = ref.watch(notesProvider(student.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: cs.primary),
                const SizedBox(width: 8),
                Text(loc.studentProfileNotes,
                    style: tt.titleMedium?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, color: cs.primary),
                  onPressed: () => _addNote(context, ref),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 12),
            notesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text(loc.studentProfileNotesLoadError('$e'),
                  style: tt.bodySmall?.copyWith(color: cs.error)),
              data: (notes) => notes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(loc.studentProfileNoNotes,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    )
                  : Column(
                      children: notes
                          .take(3)
                          .map((n) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(n.category,
                                        style: tt.labelSmall?.copyWith(
                                            color: cs.onSurfaceVariant)),
                                    const SizedBox(height: 4),
                                    Text(n.content,
                                        style: tt.bodySmall
                                            ?.copyWith(color: cs.onSurface)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote(BuildContext ctx, WidgetRef ref) async {
    final loc = AppLocalizations.of(ctx)!;
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(loc.studentProfileAddNote),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(labelText: loc.studentProfileNoteContent),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(loc.commonAdd)),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return;
    try {
      await ref.read(notesProvider(student.id).notifier).add(
            category: 'Behavior',
            content: result,
          );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(loc.commonFailed('$e'))));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.icon,
      required this.title,
      required this.cs,
      required this.tt});
  final IconData icon;
  final String title;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: tt.titleMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        const Divider(height: 12),
      ],
    );
  }
}

/// Teacher-facing login-account management for a student: shows whether the
/// student can log in and lets the teacher provision or revoke credentials.
class _AccountCard extends ConsumerWidget {
  const _AccountCard(
      {required this.student, required this.cs, required this.tt});
  final Student student;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(studentAccountProvider(student.id));
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.login, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(loc.studentProfileLoginAccount,
                    style: tt.titleMedium?.copyWith(
                        color: cs.onSurface, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            accountAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text(loc.commonCouldNotLoad('$e'),
                  style: tt.bodySmall?.copyWith(color: cs.error)),
              data: (account) => account.hasAccount
                  ? Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc.studentProfileCanSignIn,
                                  style: tt.bodyMedium
                                      ?.copyWith(color: cs.onSurface)),
                              Text(account.email ?? '',
                                  style: tt.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _revoke(context, ref),
                          child: Text(loc.studentProfileRevoke,
                              style: TextStyle(color: cs.error)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.studentProfileNoLogin,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _create(context, ref),
                          icon: const Icon(Icons.person_add_alt),
                          label: Text(loc.studentProfileCreateLogin),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(loc.studentProfileCreateLogin),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: loc.commonEmail),
                validator: (v) => (v == null || !v.contains('@'))
                    ? loc.commonInvalidEmail
                    : null,
              ),
              TextFormField(
                controller: passC,
                decoration:
                    InputDecoration(labelText: loc.studentProfileTempPassword),
                validator: (v) => (v == null || v.length < 6)
                    ? loc.commonPasswordTooShort
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(loc.commonCancel)),
          FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(d, true);
              },
              child: Text(loc.commonCreate)),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(studentAccountRepositoryProvider).create(
            student.id,
            email: emailC.text.trim(),
            password: passC.text,
          );
      ref.invalidate(studentAccountProvider(student.id));
      messenger.showSnackBar(
        SnackBar(content: Text(loc.studentProfileLoginCreated)),
      );
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.studentProfileCouldNotCreate('$e'))));
    }
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(loc.studentProfileRevokeTitle),
        content: Text(loc.studentProfileRevokeBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: Text(loc.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: Text(loc.studentProfileRevoke)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(studentAccountRepositoryProvider).delete(student.id);
      ref.invalidate(studentAccountProvider(student.id));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(loc.studentProfileCouldNotRevoke('$e'))));
    }
  }
}
