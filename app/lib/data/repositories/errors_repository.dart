import '../../core/cache/last_seen_service.dart';
import '../../domain/models/error.dart';
import '../models/error_api_model.dart';
import '../services/supabase_service.dart';

/// Repository — single source of truth (skill: Data Layer).
/// Трансформирует API-модели в доменные, кэширует last_seen_id, дедуплицирует по id.
/// last_seen_id персистится в LastSeenService (SharedPreferences) — переживает оффлайн/рестарт.
class ErrorsRepository {
  ErrorsRepository({required SupabaseService service, LastSeenService? cache}) : _service = service, _cacheService = cache;
  final SupabaseService _service;
  final LastSeenService? _cacheService;

  // in-memory кэш
  final Map<String, ErrorEntry> _cache = {};
  String? _lastSeenId;

  String? get lastSeenId => _lastSeenId;

  ErrorEntry _toDomain(ErrorApiModel api) => ErrorEntry(
        id: api.id,
        eventName: api.eventName,
        level: api.level,
        metadataObject: api.metadataObject,
        data: api.data,
        commentText: api.commentText,
        base: api.base,
        createdAt: api.createdAt,
        isRead: api.isRead,
      );

  Future<List<ErrorEntry>> getErrors({required String base, String? level}) async {
    // пробуем подгрузить last_seen из персиста если в памяти пусто
    _lastSeenId ??= _cacheService?.getLastSeenId(base);
    final apis = await _service.fetchErrors(base: base, level: level);
    final domains = apis.map(_toDomain).toList();
    for (final e in domains) {
      _cache[e.id] = e; // дедупликация
    }
    if (domains.isNotEmpty) {
      _lastSeenId = domains.first.id;
      await _cacheService?.setLastSeenId(base, _lastSeenId!);
    }
    return domains;
  }

  /// Подписка Realtime — возвращает cancel функцию
  Future<void Function()> subscribe(String base, void Function(ErrorEntry) onNew) async {
    _lastSeenId ??= _cacheService?.getLastSeenId(base);
    final channel = _service.subscribeErrors(
      base: base,
      onInsert: (api) {
        if (_cache.containsKey(api.id)) return; // дедупликация по id
        final entry = _toDomain(api);
        _cache[entry.id] = entry;
        _lastSeenId = entry.id;
        _cacheService?.setLastSeenId(base, entry.id); // fire-and-forget
        onNew(entry);
      },
    );
    return () async => await _service.client.removeChannel(channel);
  }

  Future<void> markRead(String id) async {
    await _service.markRead(id);
    final cached = _cache[id];
    if (cached != null) _cache[id] = cached.copyWith(isRead: true);
  }
}
