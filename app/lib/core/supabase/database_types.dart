// Generated via `supabase gen types --local --lang typescript` -> hand-ported to Dart
// Supabase CLI dart gen not yet stable for --lang dart (2026-08), so we keep manual dart types.
// Regenerate after schema change: `supabase gen types --local --lang typescript` and update below.
// See supabase/migrations/* and /tmp/database.ts

typedef Json = Map<String, dynamic>;

class Database {
  const Database();
}

// Helper for typed Supabase queries (optional)
class ErrorsRow {
  const ErrorsRow({
    required this.id,
    required this.eventName,
    required this.level,
    this.metadataObject,
    required this.data,
    this.commentText,
    required this.base,
    required this.createdAt,
    required this.isRead,
  });
  final String id;
  final String eventName;
  final String level;
  final String? metadataObject;
  final Json data;
  final String? commentText;
  final String base;
  final String createdAt;
  final bool isRead;

  factory ErrorsRow.fromJson(Map<String, dynamic> json) => ErrorsRow(
        id: json['id'] as String,
        eventName: json['event_name'] as String,
        level: json['level'] as String,
        metadataObject: json['metadata_object'] as String?,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        commentText: json['comment_text'] as String?,
        base: json['base'] as String,
        createdAt: json['created_at'] as String,
        isRead: json['is_read'] as bool,
      );
}
