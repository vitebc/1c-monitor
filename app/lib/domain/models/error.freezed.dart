// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ErrorEntry {

 String get id; String get eventName; String get level; String? get metadataObject; Map<String, dynamic> get data; String? get commentText; String get base; DateTime get createdAt; bool get isRead;
/// Create a copy of ErrorEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorEntryCopyWith<ErrorEntry> get copyWith => _$ErrorEntryCopyWithImpl<ErrorEntry>(this as ErrorEntry, _$identity);

  /// Serializes this ErrorEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.level, level) || other.level == level)&&(identical(other.metadataObject, metadataObject) || other.metadataObject == metadataObject)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.commentText, commentText) || other.commentText == commentText)&&(identical(other.base, base) || other.base == base)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventName,level,metadataObject,const DeepCollectionEquality().hash(data),commentText,base,createdAt,isRead);

@override
String toString() {
  return 'ErrorEntry(id: $id, eventName: $eventName, level: $level, metadataObject: $metadataObject, data: $data, commentText: $commentText, base: $base, createdAt: $createdAt, isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class $ErrorEntryCopyWith<$Res>  {
  factory $ErrorEntryCopyWith(ErrorEntry value, $Res Function(ErrorEntry) _then) = _$ErrorEntryCopyWithImpl;
@useResult
$Res call({
 String id, String eventName, String level, String? metadataObject, Map<String, dynamic> data, String? commentText, String base, DateTime createdAt, bool isRead
});




}
/// @nodoc
class _$ErrorEntryCopyWithImpl<$Res>
    implements $ErrorEntryCopyWith<$Res> {
  _$ErrorEntryCopyWithImpl(this._self, this._then);

  final ErrorEntry _self;
  final $Res Function(ErrorEntry) _then;

/// Create a copy of ErrorEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventName = null,Object? level = null,Object? metadataObject = freezed,Object? data = null,Object? commentText = freezed,Object? base = null,Object? createdAt = null,Object? isRead = null,}) {
  return _then(ErrorEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,metadataObject: freezed == metadataObject ? _self.metadataObject : metadataObject // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,commentText: freezed == commentText ? _self.commentText : commentText // ignore: cast_nullable_to_non_nullable
as String?,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ErrorEntry].
extension ErrorEntryPatterns on ErrorEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorEntry value)  $default,){
final _that = this;
switch (_that) {
case _ErrorEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String eventName,  String level,  String? metadataObject,  Map<String, dynamic> data,  String? commentText,  String base,  DateTime createdAt,  bool isRead)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorEntry() when $default != null:
return $default(_that.id,_that.eventName,_that.level,_that.metadataObject,_that.data,_that.commentText,_that.base,_that.createdAt,_that.isRead);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String eventName,  String level,  String? metadataObject,  Map<String, dynamic> data,  String? commentText,  String base,  DateTime createdAt,  bool isRead)  $default,) {final _that = this;
switch (_that) {
case _ErrorEntry():
return $default(_that.id,_that.eventName,_that.level,_that.metadataObject,_that.data,_that.commentText,_that.base,_that.createdAt,_that.isRead);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String eventName,  String level,  String? metadataObject,  Map<String, dynamic> data,  String? commentText,  String base,  DateTime createdAt,  bool isRead)?  $default,) {final _that = this;
switch (_that) {
case _ErrorEntry() when $default != null:
return $default(_that.id,_that.eventName,_that.level,_that.metadataObject,_that.data,_that.commentText,_that.base,_that.createdAt,_that.isRead);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorEntry implements ErrorEntry {
  const _ErrorEntry({required this.id, required this.eventName, required this.level, this.metadataObject,  Map<String, dynamic> data = const <String, dynamic>{}, this.commentText, required this.base, required this.createdAt, this.isRead = false}): _data = data;
  factory _ErrorEntry.fromJson(Map<String, dynamic> json) => _$ErrorEntryFromJson(json);

@override final  String id;
@override final  String eventName;
@override final  String level;
@override final  String? metadataObject;
 final  Map<String, dynamic> _data;
@override@JsonKey() Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  String? commentText;
@override final  String base;
@override final  DateTime createdAt;
@override@JsonKey() final  bool isRead;

/// Create a copy of ErrorEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorEntryCopyWith<_ErrorEntry> get copyWith => __$ErrorEntryCopyWithImpl<_ErrorEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.level, level) || other.level == level)&&(identical(other.metadataObject, metadataObject) || other.metadataObject == metadataObject)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.commentText, commentText) || other.commentText == commentText)&&(identical(other.base, base) || other.base == base)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventName,level,metadataObject,const DeepCollectionEquality().hash(_data),commentText,base,createdAt,isRead);

@override
String toString() {
  return 'ErrorEntry(id: $id, eventName: $eventName, level: $level, metadataObject: $metadataObject, data: $data, commentText: $commentText, base: $base, createdAt: $createdAt, isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class _$ErrorEntryCopyWith<$Res> implements $ErrorEntryCopyWith<$Res> {
  factory _$ErrorEntryCopyWith(_ErrorEntry value, $Res Function(_ErrorEntry) _then) = __$ErrorEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String eventName, String level, String? metadataObject, Map<String, dynamic> data, String? commentText, String base, DateTime createdAt, bool isRead
});




}
/// @nodoc
class __$ErrorEntryCopyWithImpl<$Res>
    implements _$ErrorEntryCopyWith<$Res> {
  __$ErrorEntryCopyWithImpl(this._self, this._then);

  final _ErrorEntry _self;
  final $Res Function(_ErrorEntry) _then;

/// Create a copy of ErrorEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventName = null,Object? level = null,Object? metadataObject = freezed,Object? data = null,Object? commentText = freezed,Object? base = null,Object? createdAt = null,Object? isRead = null,}) {
  return _then(_ErrorEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,metadataObject: freezed == metadataObject ? _self.metadataObject : metadataObject // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,commentText: freezed == commentText ? _self.commentText : commentText // ignore: cast_nullable_to_non_nullable
as String?,base: null == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
