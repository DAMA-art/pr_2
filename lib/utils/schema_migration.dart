import 'package:shared_preferences/shared_preferences.dart';

class SchemaMigration {
  static const versionKey = 'schema_version';
  static const currentVersion = 2;

  static const _legacyKeys = [
    'pets_v1',
    'owners_v1',
    'services_v1',
    'clinics_v1',
    'loyalty_cards_v1',
  ];

  static Future<String?> migrate(SharedPreferences prefs) async {
    final stored = prefs.getInt(versionKey);
    if (stored == currentVersion) return null;

    final hadLegacy = _legacyKeys.any((key) => prefs.containsKey(key));
    if (hadLegacy) {
      await _copyIfPresent(prefs, 'pets_v1', 'pets_v2');
      await _copyIfPresent(prefs, 'owners_v1', 'owners_v2');
      await _copyIfPresent(prefs, 'services_v1', 'services_v2');
      await _copyIfPresent(prefs, 'clinics_v1', 'clinics_v2');
      await prefs.remove('loyalty_cards_v1');
    }

    await prefs.setInt(versionKey, currentVersion);

    if (stored == null && !hadLegacy) return null;
    return 'Формат данных обновлён';
  }

  static Future<void> _copyIfPresent(SharedPreferences prefs, String from, String to) async {
    final raw = prefs.getString(from);
    if (raw == null) return;
    if (!prefs.containsKey(to)) {
      await prefs.setString(to, raw);
    }
    await prefs.remove(from);
  }
}
