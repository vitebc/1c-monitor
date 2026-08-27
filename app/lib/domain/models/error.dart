import 'package:freezed_annotation/freezed_annotation.dart';

part 'error.freezed.dart';
part 'error.g.dart';

/// Чистая доменная модель ошибки — 1 строка = 6 полей из ТЗ 1С + тех-поля.
/// Skill step 1: Define Domain Models (immutable, freezed).
@freezed
abstract class ErrorEntry with _$ErrorEntry {
  const factory ErrorEntry({
    required String id,
    required String eventName, // <ИмяСобытия>
    required String level, // Информация | Предупреждение | Ошибка | Критично
    String? metadataObject, // <ОбъектМетаданных>
    @Default(<String, dynamic>{}) Map<String, dynamic> data, // <Данные> jsonb
    String? commentText, // <Комментарий>
    required String base, // <База>
    required DateTime createdAt,
    @Default(false) bool isRead,
  }) = _ErrorEntry;

  factory ErrorEntry.fromJson(Map<String, dynamic> json) =>
      _$ErrorEntryFromJson(json);
}

extension ErrorEntryX on ErrorEntry {
  bool get isCritical => level == 'Критично' || level == 'Ошибка';
  String get shortTitle => '$level: $eventName';
}
