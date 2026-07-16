import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design.dart';
import '../../../models/grade_level.dart';
import '../../../models/post_subject.dart';
import '../../../models/search_result.dart';
import '../../feed/screens/post_detail_screen.dart';
import '../../profile/screens/teacher_profile_view_screen.dart';
import '../state/search_providers.dart';

/// Global discovery: search teachers by name and materials (shared quizzes and
/// documents) with Subject / Grade / Material-Type filters.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final cur = ref.read(searchQueryProvider);
      ref.read(searchQueryProvider.notifier).update((
        q: value,
        type: cur.type,
        subject: cur.subject,
        grade: cur.grade,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover',
                      style: tt.headlineMedium?.copyWith(
                          color: cs.onSurface, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Teachers, quizzes, documents…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  _onChanged('');
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _FilterBar(),
            Expanded(
              child: resultsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (results) => _Results(results: results),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Material-type segmented control + horizontally scrolling Subject and Grade
/// chip rows.
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final notifier = ref.read(searchQueryProvider.notifier);

    void setType(String type) => notifier.update((
          q: query.q,
          type: type,
          subject: query.subject,
          grade: query.grade,
        ));
    void setSubject(String? s) => notifier.update((
          q: query.q,
          type: query.type,
          subject: s,
          grade: query.grade,
        ));
    void setGrade(String? g) => notifier.update((
          q: query.q,
          type: query.type,
          subject: query.subject,
          grade: g,
        ));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'teachers', label: Text('Teachers')),
              ButtonSegment(value: 'quizzes', label: Text('Quizzes')),
              ButtonSegment(value: 'documents', label: Text('Docs')),
            ],
            selected: {query.type},
            onSelectionChanged: (s) => setType(s.first),
            showSelectedIcon: false,
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              for (final s in PostSubject.all)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.label),
                    selected: query.subject == s.value,
                    onSelected: (sel) => setSubject(sel ? s.value : null),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final g in GradeLevel.all)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(g.label),
                    selected: query.grade == g.value,
                    onSelected: (sel) => setGrade(sel ? g.value : null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.results});
  final SearchResults results;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore,
                  size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text('Search teachers and shared materials',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (results.teachers.isNotEmpty) ...[
          _SectionTitle('Teachers'),
          const SizedBox(height: 8),
          for (final t in results.teachers) _TeacherRow(teacher: t),
          const SizedBox(height: 16),
        ],
        if (results.materials.isNotEmpty) ...[
          _SectionTitle('Materials'),
          const SizedBox(height: 8),
          for (final m in results.materials) _MaterialRow(material: m),
        ],
      ],
    );
  }
}

class _TeacherRow extends StatelessWidget {
  const _TeacherRow({required this.teacher});
  final TeacherResult teacher;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TeacherProfileViewScreen(userId: teacher.userId),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
              child: Text(_initials(teacher.name),
                  style: tt.labelLarge?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(teacher.name,
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material});
  final MaterialResult material;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final m = material;
    final grade = GradeLevel.labelFor(m.gradeLevel);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: m.postId),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: (m.isQuiz ? cs.tertiary : cs.secondary)
                  .withValues(alpha: 0.15),
              child: Icon(
                  m.isQuiz ? Icons.quiz_outlined : Icons.description_outlined,
                  color: m.isQuiz ? cs.tertiary : cs.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    [
                      m.type,
                      PostSubject.labelFor(m.subject),
                      if (grade != null) grade,
                      'by ${m.authorName}',
                    ].join(' · '),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}
