// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoMapprGenerator
// **************************************************************************

// ignore_for_file: type=lint, unnecessary_cast, unused_local_variable

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_mappr_annotation/auto_mappr_annotation.dart' as _i1;

import '../data/models/note_entity.dart' as _i5;
import '../data/models/task_entity.dart' as _i3;
import '../domain/models/note.dart' as _i4;
import '../domain/models/task.dart' as _i2;
import 'home_mappr.dart' as _i6;

/// {@template package:foundation_project/features/home/mappers/home_mappr.dart}
/// Available mappings:
/// - `Task` → `TaskEntity`.
/// - `TaskEntity` → `Task`.
/// - `Note` → `NoteEntity`.
/// - `NoteEntity` → `Note`.
/// {@endtemplate}
class $HomeMappr implements _i1.AutoMapprInterface {
  const $HomeMappr();

  Type _typeOf<T>() => T;

  List<_i1.AutoMapprInterface> get _delegates => const [];

  /// {@macro AutoMapprInterface:canConvert}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  bool canConvert<SOURCE, TARGET>({bool recursive = true}) {
    final sourceTypeOf = _typeOf<SOURCE>();
    final targetTypeOf = _typeOf<TARGET>();
    if ((sourceTypeOf == _typeOf<_i2.Task>() ||
            sourceTypeOf == _typeOf<_i2.Task?>()) &&
        (targetTypeOf == _typeOf<_i3.TaskEntity>() ||
            targetTypeOf == _typeOf<_i3.TaskEntity?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i3.TaskEntity>() ||
            sourceTypeOf == _typeOf<_i3.TaskEntity?>()) &&
        (targetTypeOf == _typeOf<_i2.Task>() ||
            targetTypeOf == _typeOf<_i2.Task?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i4.Note>() ||
            sourceTypeOf == _typeOf<_i4.Note?>()) &&
        (targetTypeOf == _typeOf<_i5.NoteEntity>() ||
            targetTypeOf == _typeOf<_i5.NoteEntity?>())) {
      return true;
    }
    if ((sourceTypeOf == _typeOf<_i5.NoteEntity>() ||
            sourceTypeOf == _typeOf<_i5.NoteEntity?>()) &&
        (targetTypeOf == _typeOf<_i4.Note>() ||
            targetTypeOf == _typeOf<_i4.Note?>())) {
      return true;
    }
    if (recursive) {
      for (final mappr in _delegates) {
        if (mappr.canConvert<SOURCE, TARGET>()) {
          return true;
        }
      }
    }
    return false;
  }

  /// {@macro AutoMapprInterface:convert}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  TARGET convert<SOURCE, TARGET>(SOURCE? model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return _convert(model)!;
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convert(model)!;
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// {@macro AutoMapprInterface:tryConvert}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  TARGET? tryConvert<SOURCE, TARGET>(
    SOURCE? model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
        onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return _safeConvert(
        model,
        onMappingError: onMappingError,
      );
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvert(
          model,
          onMappingError: onMappingError,
        );
      }
    }

    return null;
  }

  /// {@macro AutoMapprInterface:convertIterable}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  Iterable<TARGET> convertIterable<SOURCE, TARGET>(Iterable<SOURCE?> model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return model.map<TARGET>((item) => _convert(item)!);
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convertIterable(model);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// For iterable items, converts from SOURCE to TARGET if such mapping is configured, into Iterable.
  ///
  /// When an item in the source iterable is null, uses `whenSourceIsNull` if defined or null
  ///
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  Iterable<TARGET?> tryConvertIterable<SOURCE, TARGET>(
    Iterable<SOURCE?> model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
        onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return model.map<TARGET?>(
          (item) => _safeConvert(item, onMappingError: onMappingError));
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvertIterable(
          model,
          onMappingError: onMappingError,
        );
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// {@macro AutoMapprInterface:convertList}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  List<TARGET> convertList<SOURCE, TARGET>(Iterable<SOURCE?> model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return convertIterable<SOURCE, TARGET>(model).toList();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convertList(model);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// For iterable items, converts from SOURCE to TARGET if such mapping is configured, into List.
  ///
  /// When an item in the source iterable is null, uses `whenSourceIsNull` if defined or null
  ///
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  List<TARGET?> tryConvertList<SOURCE, TARGET>(
    Iterable<SOURCE?> model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
        onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return tryConvertIterable<SOURCE, TARGET>(
        model,
        onMappingError: onMappingError,
      ).toList();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvertList(
          model,
          onMappingError: onMappingError,
        );
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// {@macro AutoMapprInterface:convertSet}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  Set<TARGET> convertSet<SOURCE, TARGET>(Iterable<SOURCE?> model) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return convertIterable<SOURCE, TARGET>(model).toSet();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.convertSet(model);
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  /// For iterable items, converts from SOURCE to TARGET if such mapping is configured, into Set.
  ///
  /// When an item in the source iterable is null, uses `whenSourceIsNull` if defined or null
  ///
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  Set<TARGET?> tryConvertSet<SOURCE, TARGET>(
    Iterable<SOURCE?> model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
        onMappingError,
  }) {
    if (canConvert<SOURCE, TARGET>(recursive: false)) {
      return tryConvertIterable<SOURCE, TARGET>(
        model,
        onMappingError: onMappingError,
      ).toSet();
    }
    for (final mappr in _delegates) {
      if (mappr.canConvert<SOURCE, TARGET>()) {
        return mappr.tryConvertSet(
          model,
          onMappingError: onMappingError,
        );
      }
    }

    throw Exception('No ${_typeOf<SOURCE>()} -> ${_typeOf<TARGET>()} mapping.');
  }

  TARGET? _convert<SOURCE, TARGET>(
    SOURCE? model, {
    bool canReturnNull = false,
  }) {
    final sourceTypeOf = _typeOf<SOURCE>();
    final targetTypeOf = _typeOf<TARGET>();
    if ((sourceTypeOf == _typeOf<_i2.Task>() ||
            sourceTypeOf == _typeOf<_i2.Task?>()) &&
        (targetTypeOf == _typeOf<_i3.TaskEntity>() ||
            targetTypeOf == _typeOf<_i3.TaskEntity?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i2$Task_To__i3$TaskEntity((model as _i2.Task?)) as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i3.TaskEntity>() ||
            sourceTypeOf == _typeOf<_i3.TaskEntity?>()) &&
        (targetTypeOf == _typeOf<_i2.Task>() ||
            targetTypeOf == _typeOf<_i2.Task?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i3$TaskEntity_To__i2$Task((model as _i3.TaskEntity?))
          as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i4.Note>() ||
            sourceTypeOf == _typeOf<_i4.Note?>()) &&
        (targetTypeOf == _typeOf<_i5.NoteEntity>() ||
            targetTypeOf == _typeOf<_i5.NoteEntity?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i4$Note_To__i5$NoteEntity((model as _i4.Note?)) as TARGET);
    }
    if ((sourceTypeOf == _typeOf<_i5.NoteEntity>() ||
            sourceTypeOf == _typeOf<_i5.NoteEntity?>()) &&
        (targetTypeOf == _typeOf<_i4.Note>() ||
            targetTypeOf == _typeOf<_i4.Note?>())) {
      if (canReturnNull && model == null) {
        return null;
      }
      return (_map__i5$NoteEntity_To__i4$Note((model as _i5.NoteEntity?))
          as TARGET);
    }
    throw Exception('No ${model.runtimeType} -> $targetTypeOf mapping.');
  }

  TARGET? _safeConvert<SOURCE, TARGET>(
    SOURCE? model, {
    void Function(Object error, StackTrace stackTrace, SOURCE? source)?
        onMappingError,
  }) {
    if (!useSafeMapping<SOURCE, TARGET>()) {
      return _convert(
        model,
        canReturnNull: true,
      );
    }
    try {
      return _convert(
        model,
        canReturnNull: true,
      );
    } catch (e, s) {
      onMappingError?.call(e, s, model);
      return null;
    }
  }

  /// {@macro AutoMapprInterface:useSafeMapping}
  /// {@macro package:foundation_project/features/home/mappers/home_mappr.dart}
  @override
  bool useSafeMapping<SOURCE, TARGET>() {
    return false;
  }

  _i3.TaskEntity _map__i2$Task_To__i3$TaskEntity(_i2.Task? input) {
    final model = input;
    if (model == null) {
      throw Exception(
          r'Mapping Task → TaskEntity failed because Task was null, and no default value was provided. '
          r'Consider setting the whenSourceIsNull parameter on the MapType<Task, TaskEntity> to handle null values during mapping.');
    }
    return _i3.TaskEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      status: _i6.HomeMappr.taskStatusToString(model),
      priority: _i6.HomeMappr.taskPriorityToString(model),
      dueDate: model.dueDate,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      syncStatus: _i6.HomeMappr.defaultSyncStatus(model),
      version: _i6.HomeMappr.defaultVersion(model),
    );
  }

  _i2.Task _map__i3$TaskEntity_To__i2$Task(_i3.TaskEntity? input) {
    final model = input;
    if (model == null) {
      throw Exception(
          r'Mapping TaskEntity → Task failed because TaskEntity was null, and no default value was provided. '
          r'Consider setting the whenSourceIsNull parameter on the MapType<TaskEntity, Task> to handle null values during mapping.');
    }
    return _i2.Task(
      id: model.id,
      title: model.title,
      description: model.description,
      status: _i6.HomeMappr.stringToTaskStatus(model),
      priority: _i6.HomeMappr.stringToTaskPriority(model),
      dueDate: model.dueDate,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  _i5.NoteEntity _map__i4$Note_To__i5$NoteEntity(_i4.Note? input) {
    final model = input;
    if (model == null) {
      throw Exception(
          r'Mapping Note → NoteEntity failed because Note was null, and no default value was provided. '
          r'Consider setting the whenSourceIsNull parameter on the MapType<Note, NoteEntity> to handle null values during mapping.');
    }
    return _i5.NoteEntity(
      id: model.id,
      title: model.title,
      content: model.content,
      tags: model.tags,
      isFavorite: model.isFavorite,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      syncStatus: _i6.HomeMappr.defaultSyncStatusNote(model),
      version: _i6.HomeMappr.defaultVersionNote(model),
    );
  }

  _i4.Note _map__i5$NoteEntity_To__i4$Note(_i5.NoteEntity? input) {
    final model = input;
    if (model == null) {
      throw Exception(
          r'Mapping NoteEntity → Note failed because NoteEntity was null, and no default value was provided. '
          r'Consider setting the whenSourceIsNull parameter on the MapType<NoteEntity, Note> to handle null values during mapping.');
    }
    return _i4.Note(
      id: model.id,
      title: model.title,
      content: model.content,
      tags: model.tags,
      isFavorite: model.isFavorite,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
