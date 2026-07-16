import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/search_result.dart';
import '../data/search_repository.dart';

/// The current search query + filters. `type` is one of all/teachers/quizzes/
/// documents; `subject`/`grade` are wire enum values or null.
typedef SearchQuery = ({String q, String type, String? subject, String? grade});

const emptyQuery = (q: '', type: 'all', subject: null, grade: null);

/// Riverpod 3 removed [StateProvider] — use a plain [Notifier] instead.
/// Callers: `ref.watch(searchQueryProvider)` for the value,
///          `ref.read(searchQueryProvider.notifier).update(…)` to change it.
class SearchQueryNotifier extends Notifier<SearchQuery> {
  @override
  SearchQuery build() => emptyQuery;

  void update(SearchQuery q) => state = q;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, SearchQuery>(SearchQueryNotifier.new);

/// Results for the current query. Returns empty until there's a term or a
/// material filter to act on (nothing to show on an untouched screen).
final searchResultsProvider = FutureProvider<SearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final hasTerm = query.q.trim().isNotEmpty;
  final hasFilter = query.subject != null || query.grade != null;
  if (!hasTerm && !hasFilter) {
    return const SearchResults(teachers: [], materials: []);
  }
  return ref.watch(searchRepositoryProvider).search(
        q: hasTerm ? query.q.trim() : null,
        type: query.type,
        subject: query.subject,
        grade: query.grade,
      );
});
