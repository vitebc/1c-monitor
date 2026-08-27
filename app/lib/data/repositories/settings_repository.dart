import '../services/supabase_service.dart';

/// Repository для подписок на базы (skill: Data Layer)
class SettingsRepository {
  SettingsRepository({required SupabaseService service}) : _service = service;
  final SupabaseService _service;

  Future<List<String>> getMyBases() => _service.fetchMyBases();
  Future<void> addBase(String base) => _service.addBase(base.trim());
  Future<void> removeBase(String base) => _service.removeBase(base);
}
