import 'package:shared_preferences/shared_preferences.dart';

const _kAdbPathKey = 'adb_path';

/// Persists and retrieves app settings (e.g. ADB path).
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  String get adbPath => _prefs.getString(_kAdbPathKey) ?? 'adb';

  Future<void> setAdbPath(String path) async {
    await _prefs.setString(_kAdbPathKey, path.trim());
  }
}
