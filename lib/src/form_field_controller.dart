import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

class ListFieldController<T> extends FieldController<List<T>> {
  ListFieldController(super.value) : super(emptyValue: []);

  @override
  bool get isEmpty => value.isEmpty;
}

class NullableFieldController<T> extends FieldController<T?> {
  NullableFieldController(super.value) : super(emptyValue: null);

  @override
  bool get isEmpty => value == null;
}

class FieldController<T> extends BaseFieldController<T, T> {
  FieldController(
    super.value, {
    required super.emptyValue,
  });

  @override
  T fieldValueOf(T value) => value;
  @override
  T valueOf(T fieldValue) => fieldValue;
}

abstract class BaseFieldController<T, FT> extends ValueNotifier<T>
    with FieldControllerMixin<T> {
  BaseFieldController(
    super.value, {
    required this.emptyValue,
  });

  @override
  final T? emptyValue;

  FT get fieldValue => fieldValueOf(value);
  set fieldValue(FT fieldValue) => value = valueOf(fieldValue);

  FT fieldValueOf(T value);
  T valueOf(FT fieldValue);
}

mixin FieldControllerMixin<T> implements ValueNotifier<T> {
  T? get emptyValue;
  late T _savedValue = value;
  T get savedValue => _savedValue;

  bool get unsaved => !(savedValue == value);

  bool get isEmpty => value == emptyValue;

  final didRestore = ChangeNotifier();
  final didClear = ChangeNotifier();
  final didSave = ChangeNotifier();

  @mustCallSuper
  void save() {
    Log.i("ListFormFieldController.save");
    _savedValue = value;
    didSave.notifyListeners();
  }

  @mustCallSuper
  void restore() {
    Log.i("ListFormFieldController.restore");
    value = _savedValue;
    didRestore.notifyListeners();
  }

  @mustCallSuper
  void clear() {
    Log.i("ListFormFieldController.clear");
    if (emptyValue is T) {
      value = emptyValue as T;
      didClear.notifyListeners();
    }
  }

  @override
  void dispose() {
    didSave.dispose();
    didClear.dispose();
    didRestore.dispose();
  }
}
