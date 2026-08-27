import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/error_api_model.dart';

/// Stateless Service — обёртка над Supabase (skill: Data Layer -> Services).
/// Возвращает сырые API-модели, без бизнес-логики.
class SupabaseService {
  SupabaseService(this._client);
  final SupabaseClient _client;

  SupabaseClient get client => _client;

  // --- errors ---
  Future<List<ErrorApiModel>> fetchErrors({
    required String base,
    int limit = 50,
    String? level,
  }) async {
    var query = _client
        .from('errors')
        .select()
        .eq('base', base)
        .order('created_at', ascending: false)
        .limit(limit);
    if (level != null) query = query.eq('level', level);
    final rows = await query;
    return (rows as List).map((e) => ErrorApiModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Realtime stream: новые строки по base (fallback когда FCM недоступен)
  RealtimeChannel subscribeErrors({
    required String base,
    required void Function(ErrorApiModel) onInsert,
  }) {
    final channel = _client.channel('errors:$base');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'errors',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'base', value: base),
          callback: (payload) {
            final rec = payload.newRecord;
            onInsert(ErrorApiModel.fromJson(rec));
          },
        )
        .subscribe();
    return channel;
  }

  Future<void> markRead(String id) async {
    await _client.from('errors').update({'is_read': true}).eq('id', id);
  }

  // --- device token ---
  Future<void> upsertDeviceToken({required String token, required String platform}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('device_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'last_seen_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'token',
    );
  }

  // --- bases subscription ---
  Future<List<String>> fetchMyBases() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client.from('user_bases').select('base').eq('user_id', userId);
    return (rows as List).map((e) => e['base'] as String).toList();
  }

  Future<void> addBase(String base) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('user_bases').insert({'user_id': userId, 'base': base});
  }

  Future<void> removeBase(String base) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('user_bases').delete().eq('user_id', userId).eq('base', base);
  }
}
