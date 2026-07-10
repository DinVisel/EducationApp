import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/admin_report.dart';
import '../../../models/admin_user.dart';
import '../data/admin_repository.dart';

/// Reports for the admin queue, keyed by whether to show resolved ones.
final adminReportsProvider =
    FutureProvider.family<List<AdminReport>, bool>((ref, resolved) {
  return ref.watch(adminRepositoryProvider).getReports(resolved: resolved);
});

/// All user accounts.
final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).getUsers();
});

/// Resolve helpers that refresh the open + resolved report lists afterwards.
class AdminActions {
  AdminActions(this._ref);
  final Ref _ref;

  Future<void> dismiss(int reportId) async {
    await _ref.read(adminRepositoryProvider).dismiss(reportId);
    _invalidate();
  }

  Future<void> removeContent(int reportId) async {
    await _ref.read(adminRepositoryProvider).removeContent(reportId);
    _invalidate();
  }

  void _invalidate() {
    _ref.invalidate(adminReportsProvider(false));
    _ref.invalidate(adminReportsProvider(true));
  }
}

final adminActionsProvider = Provider<AdminActions>((ref) => AdminActions(ref));
