// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ErrorEntry _$ErrorEntryFromJson(Map<String, dynamic> json) => _ErrorEntry(
  id: json['id'] as String,
  eventName: json['eventName'] as String,
  level: json['level'] as String,
  metadataObject: json['metadataObject'] as String?,
  data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  commentText: json['commentText'] as String?,
  base: json['base'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  isRead: json['isRead'] as bool? ?? false,
);

Map<String, dynamic> _$ErrorEntryToJson(_ErrorEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'eventName': instance.eventName,
      'level': instance.level,
      'metadataObject': instance.metadataObject,
      'data': instance.data,
      'commentText': instance.commentText,
      'base': instance.base,
      'createdAt': instance.createdAt.toIso8601String(),
      'isRead': instance.isRead,
    };
