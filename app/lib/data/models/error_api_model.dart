/// Сырая API-модель — 1:1 с колонками public.errors (Supabase).
/// Repository трансформирует её в domain ErrorEntry.
class ErrorApiModel {
  const ErrorApiModel({
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
  final Map<String, dynamic> data;
  final String? commentText;
  final String base;
  final DateTime createdAt;
  final bool isRead;

  factory ErrorApiModel.fromJson(Map<String, dynamic> json) {
    return ErrorApiModel(
      id: json['id'] as String,
      eventName: json['event_name'] as String,
      level: json['level'] as String,
      metadataObject: json['metadata_object'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      commentText: json['comment_text'] as String?,
      base: json['base'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_name': eventName,
        'level': level,
        'metadata_object': metadataObject,
        'data': data,
        'comment_text': commentText,
        'base': base,
        'created_at': createdAt.toIso8601String(),
        'is_read': isRead,
      };
}
