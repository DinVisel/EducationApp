import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'haptic_controller.dart';

/// Thin wrapper around [HapticFeedback] that respects the user's haptics
/// preference. Grab via `ref.read(hapticServiceProvider)` and call the
/// semantic methods — the service no-ops when haptics are disabled.
class HapticService {
  HapticService(this._ref);

  final Ref _ref;

  bool get _enabled =>
      _ref.read(hapticControllerProvider).value ?? true;

  /// Light selection click — tab switches, toggle taps, list item taps.
  void tap() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  /// Medium impact — save success, post created, action completed.
  void success() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  /// Heavy impact — destructive action confirmations (delete, sign out).
  void warning() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  /// Long vibrate — form validation failure, error states.
  void error() {
    if (_enabled) HapticFeedback.vibrate();
  }
}

final hapticServiceProvider = Provider<HapticService>(HapticService.new);
