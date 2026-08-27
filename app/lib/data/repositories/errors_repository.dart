import '../../domain/models/error.dart';
import '../models/error_api_model.dart';
import '../services/supabase_service.dart';

/// Repository — single source of truth (skill: Data Layer).
/// Трансформирует API-модели в доменные, кэширует last_seen_id, дедуплицирует по id.
class ErrorsRepository {
  ErrorsRepository({required SupabaseService service}) : _service = service;
  final SupabaseService _service;

  // in-memory кэш (для хива/drift можно заменить)
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
    final apis = await _service.fetchErrors(base: base, level: level);
    final domains = apis.map(_toDomain).toList();
    for (final e in domains) {
      _cache[e.id] = e; // дедупликация
    }
    if (domains.isNotEmpty) _lastSeenId = domains.first.id;
    return domains;
  }

  /// Подписка Realtime — возвращает cancel функцию
  Future<void Function()> subscribe(String base, void Function(ErrorEntry) onNew) async {
    final channel = _service.subscribeErrors(
      base: base,
      onInsert: (api) {
        if (_cache.containsKey(api.id)) return; // дедупликация по id
        final entry = _toDomain(api);
        _cache[entry.id] = entry;
        _lastSeenId = entry.id;
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
