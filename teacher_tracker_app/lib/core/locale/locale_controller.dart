import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_locale';

/// The app's display language. Null means "follow the system locale" (clamped
/// to a supported language by [AppLocalizations]).
class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncData(locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);
