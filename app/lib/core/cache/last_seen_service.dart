import 'package:shared_preferences/shared_preferences.dart';

/// Локальный кэш last_seen_id per base (skill: Data Layer -> Services)
/// Хранит последний id ошибки для дедупликации и badge'ей, переживает оффлайн.
class LastSeenService {
  LastSeenService(this._prefs);
  final SharedPreferences _prefs;

  static Future<LastSeenService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LastSeenService(prefs);
  }

  static const _prefix = 'last_seen_';

  String? getLastSeenId(String base) => _prefs.getString('$_prefix$base');

  Future<void> setLastSeenId(String base, String id) async {
    await _prefs.setString('$_prefix$base', id);
  }

  Future<void> clearBase(String base) async {
    await _prefs.remove('$_prefix$base');
  }

  // unread badge — считаем локально как разницу между last_seen и текущими
  int getUnreadCount(List<String> allIds, String? lastSeenId) {
    if (lastSeenId == null) return allIds.length;
    final idx = allIds.indexOf(lastSeenId);
    if (idx == -1) return allIds.length;
    return idx; // так как список отсортирован DESC, новые — до lastSeen
  }
}
