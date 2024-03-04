import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

mixin class EditablePropsMixin {
  late final bool? enabled;
  late final bool? readOnly;
  late final bool? clearable;
  late final bool? restoreable;

  void initEditableProps({
    bool? enabled,
    bool? readOnly,
    bool? clearable,
    bool? restoreable,
  }) {
    this.enabled = enabled;
    this.readOnly = readOnly;
    this.clearable = clearable;
    this.restoreable = restoreable;
  }

  EditableProps copyWith<T>({
    (bool?,)? enabled,
    (bool?,)? readOnly,
    (bool?,)? clearable,
    (bool?,)? restoreable,
  }) {
    return EditableProps(
      enabled: enabled != null ? enabled.$1 : this.enabled,
      readOnly: readOnly != null ? readOnly.$1 : this.readOnly,
      clearable: clearable != null ? clearable.$1 : this.clearable,
      restoreable: restoreable != null ? restoreable.$1 : this.restoreable,
    );
  }

  bool isEditablePropsEquals(EditablePropsMixin other) {
    return other.enabled == enabled &&
        other.readOnly == readOnly &&
        other.clearable == clearable &&
        other.restoreable == restoreable;
  }

  EditableProps scoped(final EditablePropsMixin? scopeProps) {
    return EditableProps(
      enabled: (enabled != null && scopeProps?.enabled != null)
          ? (enabled! && scopeProps!.enabled!)
          : (enabled ?? scopeProps?.enabled),
      readOnly: (readOnly != null && scopeProps?.readOnly != null)
          ? (readOnly! || scopeProps!.readOnly!)
          : (readOnly ?? scopeProps?.readOnly),
      clearable: clearable ?? scopeProps?.clearable,
      restoreable: restoreable ?? scopeProps?.restoreable,
    );
  }

  String symbol(bool? enabled) =>
      switch (enabled) { null => " ", true => "Y", false => "-" };

  String editablePropsToString() {
    return 'Props(enabled: ${symbol(enabled)}, readOnly: ${symbol(readOnly)}, '
        'clearable: ${symbol(clearable)}, restoreable: ${symbol(restoreable)})';
  }
}

abstract class _EditablePropsBase with EditablePropsMixin {
  _EditablePropsBase({
    bool? enabled,
    bool? readOnly,
    bool? clearable,
    bool? restoreable,
  }) {
    this.enabled = enabled;
    this.readOnly = readOnly;
    this.clearable = clearable;
    this.restoreable = restoreable;
  }

  @override
  bool operator ==(Object other) =>
      other is EditablePropsMixin && isEditablePropsEquals(other);

  @override
  int get hashCode => Object.hash(enabled, readOnly, clearable, restoreable);

  @override
  String toString() {
    return editablePropsToString();
  }
}

final class EditableProps extends _EditablePropsBase {
  EditableProps({
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
  });

  ComputedEditableProps computed() {
    return ComputedEditableProps._(
      enabled: enabled ?? true,
      readOnly: readOnly ?? false,
      clearable: clearable ?? true,
      restoreable: restoreable ?? true,
    );
  }
}

final class ComputedEditableProps extends _EditablePropsBase
    with EditablePropsMixin {
  ComputedEditableProps._({
    bool super.enabled = true,
    bool super.readOnly = false,
    bool super.clearable = true,
    bool super.restoreable = true,
  });

  @override
  bool get enabled => super.enabled ?? true;
  @override
  bool get readOnly => super.readOnly ?? false;
  @override
  bool get clearable => super.clearable ?? true;
  @override
  bool get restoreable => super.restoreable ?? true;

  bool get active => !readOnly && enabled;

  @override
  String toString() {
    return 'Computed${super.toString()}';
  }
}

abstract class EditablePropsWidget extends StatefulWidget
    with EditablePropsMixin {
  EditablePropsWidget({
    super.key,
    bool? enabled,
    bool? readOnly,
    bool? clearable,
    bool? restoreable,
  }) {
    initEditableProps(
      enabled: enabled,
      readOnly: readOnly,
      clearable: clearable,
      restoreable: restoreable,
    );
  }
}

abstract class ScopedEditablePropsWidgetState<W extends EditablePropsWidget>
    extends LnState<W> with EditablePropsRef, ComputedEditableStateMixin {
  @override
  EditablePropsMixin get _editableProps => widget;
  @override
  EditablePropsMixin? get _editableScopeProps => editableScopeProps;

  EditablePropsMixin? get editableScopeProps;

  @override
  void notifyEditableScopePropsChanged() {
    super.notifyEditableScopePropsChanged();

    rebuild();
  }

  @override
  void initState() {
    super.initState();

    notifyEditablePropsChanged();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isEditablePropsEquals(oldWidget)) {
      notifyEditablePropsChanged();
    }
  }
}

abstract class EditableScopeWidgetEditableState<W extends EditablePropsWidget>
    extends LnState<W> with EditableStateMixin, ComputedEditableStateMixin {
  @override
  EditablePropsMixin? get _editableScopeProps => mounted ? widget : null;

  @override
  void onScopedEditableStateChanged() {
    super.onScopedEditableStateChanged();
    rebuild();
  }

  @override
  void initState() {
    super.initState();

    notifyEditableScopePropsChanged();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isEditablePropsEquals(oldWidget)) {
      notifyEditableScopePropsChanged();
    }
  }
}

mixin ComputedEditableStateMixin
    implements EditablePropsRef, EditableScopePropsRef {
  late EditableProps _scopedState = _editableProps.scoped(_editableScopeProps);
  EditableProps get scopedState => _scopedState;

  late ComputedEditableProps _computedState = scopedState.computed();
  ComputedEditableProps get computedState => _computedState;

  @override
  @mustCallSuper
  void notifyEditablePropsChanged() {
    _computeState();
  }

  @override
  @mustCallSuper
  void notifyEditableScopePropsChanged() {
    _computeState();
  }

  @mustCallSuper
  void onScopedEditableStateChanged() {
    final newComputedState = scopedState.computed();
    if (!newComputedState.isEditablePropsEquals(computedState)) {
      _computedState = newComputedState;
      onComputedEditableStateChanged();
    }
  }

  void onComputedEditableStateChanged();

  void _computeState() {
    final newScopedState = _editableProps.scoped(_editableScopeProps);
    if (!scopedState.isEditablePropsEquals(newScopedState)) {
      _scopedState = newScopedState;
      onScopedEditableStateChanged();
    }
  }

  void logEditableProps() {
    Log.i("        ${_editableProps.editablePropsToString()}");
    Log.i("   Scope${_editableScopeProps?.editablePropsToString()}");
    Log.i(computedState);
  }
}

mixin EditableStateMixin implements EditablePropsRef {
  @override
  EditableProps _editableProps = EditableProps();

  void _setProps(EditableProps value) {
    if (!_editableProps.isEditablePropsEquals(value)) {
      _editableProps = value.copyWith();
      notifyEditablePropsChanged();
    }
  }

  set enabled(bool? val) => _setProps(_editableProps.copyWith(enabled: (val,)));

  set readOnly(bool? val) =>
      _setProps(_editableProps.copyWith(readOnly: (val,)));

  set clearable(bool? val) =>
      _setProps(_editableProps.copyWith(clearable: (val,)));

  set restoreable(bool? val) =>
      _setProps(_editableProps.copyWith(restoreable: (val,)));
}

mixin EditableScopePropsRef {
  EditablePropsMixin? get _editableScopeProps;
  void notifyEditableScopePropsChanged();
}

mixin EditablePropsRef {
  EditablePropsMixin get _editableProps;
  void notifyEditablePropsChanged();
}
