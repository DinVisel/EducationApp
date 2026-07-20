import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Turkey's 81 provinces, each with its districts. Loaded once from the bundled
/// `assets/data/tr_provinces.json` (official İçişleri Bakanlığı list, already
/// Turkish-title-cased and alphabetically sorted). Backing the profile-setup
/// dropdowns with a fixed list is what keeps the admin analytics' GROUP BY clean
/// — every teacher in a city sends the exact same canonical string.
class TrLocations {
  const TrLocations(this._provinces);

  final List<TrProvince> _provinces;

  List<TrProvince> get provinces => _provinces;

  List<String> get provinceNames =>
      _provinces.map((p) => p.name).toList(growable: false);

  /// The districts for [province], or an empty list if it's unknown/unset.
  List<String> districtsOf(String? province) {
    if (province == null) return const [];
    for (final p in _provinces) {
      if (p.name == province) return p.districts;
    }
    return const [];
  }

  factory TrLocations.fromJson(List<dynamic> json) => TrLocations([
        for (final e in json)
          TrProvince(
            (e as Map<String, dynamic>)['province'] as String,
            ((e['districts'] as List<dynamic>).cast<String>()),
          ),
      ]);
}

class TrProvince {
  const TrProvince(this.name, this.districts);
  final String name;
  final List<String> districts;
}

/// Loads and caches the province/district dataset. `keepAlive` so the ~13 KB
/// parse happens at most once per app run.
final trLocationsProvider = FutureProvider<TrLocations>((ref) async {
  ref.keepAlive();
  final raw = await rootBundle.loadString('assets/data/tr_provinces.json');
  return TrLocations.fromJson(jsonDecode(raw) as List<dynamic>);
});
