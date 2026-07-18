import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'haptics_enabled';

/// Whether haptic feedback is enabled. Defaults to `true`; the user can toggle
/// it from Settings → Haptics. Mirrors [ThemeController] / [LocaleController].
class HapticController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}

final hapticControllerProvider =
    AsyncNotifierProvider<HapticController, bool>(HapticController.new);
