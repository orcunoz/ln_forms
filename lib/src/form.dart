import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ln_alerts/ln_alerts.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/form_field_decorator.dart';
import 'package:ln_forms/src/utilities/logger.dart';

import 'editable_scope.dart';
import 'form_actions.dart';
import 'form_field_gestures.dart';
import 'form_field_logger.dart';

part 'form_button.dart';
part 'form_scope.dart';
part 'form_field.dart';
part 'future_form_field.dart';
part 'unsaved_forms_observer.dart';

enum FormModes { view, edit }

enum AutovalidateMode {
  disabled,
  alwaysAfterFirst,
  always,
}

class LnForm<R> extends EditablePropsWidget
    implements UnsavedChangesNotifiableWidget {
  LnForm({
    super.key,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.alwaysAfterFirst,
    required this.child,
    this.showUnsavedChangesMark = false,
    this.notifyUnsavedChanges = false,
    this.onSubmit,
  });

  final VoidCallback? onChanged;
  final FutureOr<R> Function(LnFormState<R>)? onSubmit;
  final bool showUnsavedChangesMark;
  final Widget child;
  final AutovalidateMode autovalidateMode;

  @override
  final bool notifyUnsavedChanges;

  @override
  State<LnForm<R>> createState() => LnFormState<R>();

  static LnFormState? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LnFormScope>();
    return scope?.state;
  }

  static LnFormState of(BuildContext context) {
    final LnFormState? state = maybeOf(context);
    assert(() {
      if (state == null) {
        throw FlutterError(
          'LnForm.of() was called with a context that does not contain a LnForm widget.\n'
          'No LnForm widget ancestor could be found starting from the context that '
          'was passed to LnForm.of(). This can happen because you are using a widget '
          'that looks for a LnForm ancestor, but no such ancestor exists.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return state!;
  }
}

abstract class LnFormFieldsHostState<R>
    extends EditableScopeWidgetEditableState<LnForm<R>>
    with UnsavedChangesNotifiableStateMixin<LnForm<R>> {
  bool _triedToValidate = false;
  final Set<LnFormFieldState> _fields = <LnFormFieldState>{};
  final Set<LnFormButtonState> _buttons = <LnFormButtonState>{};

  @override
  void didScopedEditableStateChanged() {
    super.didScopedEditableStateChanged();
    for (var field in _fields) {
      field.setEditableScopeProps(scopedState);
    }
  }

  @override
  void didComputedEditableStateChanged() {
    super.didComputedEditableStateChanged();
    for (var button in _buttons) {
      button.rebuild();
    }
  }

  bool get isEmpty => !_fields.any((f) => !f.controller.isEmpty);

  @override
  bool get hasUnsavedChanges => _fields.any((f) => f.controller.unsaved);

  @mustCallSuper
  void handleFieldValueChanged() {
    final validateFields = switch (widget.autovalidateMode) {
      AutovalidateMode.disabled => false,
      AutovalidateMode.alwaysAfterFirst => _triedToValidate,
      AutovalidateMode.always => true,
    };
    if (validateFields) {
      for (final LnFormFieldState field in _fields) {
        field.validate();
      }
    }

    if (widget.onChanged != null) {
      widget.onChanged!();
    }
  }

  void _register(LnFormFieldState field) {
    _fields.add(field);
    field.setEditableScopeProps(scopedState);
  }

  void _unregister(LnFormFieldState field) {
    _fields.remove(field);
  }

  void _registerButton(LnFormButtonState button) {
    _buttons.add(button);
  }

  void _unregisterButton(LnFormButtonState button) {
    _buttons.remove(button);
  }

  bool validate() {
    _triedToValidate = true;
    bool hasError = false;
    String errorMessage = '';
    for (final LnFormFieldState field in _fields) {
      hasError = !field.validate() || hasError;
      errorMessage += field.errorText ?? '';
    }

    if (errorMessage.isNotEmpty) {
      final TextDirection directionality = Directionality.of(context);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        unawaited(Future<void>(() async {
          await Future<void>.delayed(const Duration(seconds: 1));
          SemanticsService.announce(errorMessage, directionality,
              assertiveness: Assertiveness.assertive);
        }));
      } else {
        SemanticsService.announce(errorMessage, directionality,
            assertiveness: Assertiveness.assertive);
      }
    }
    return !hasError;
  }

  FutureOr<void> ensureVisibleErrorField() {
    return _fields.where((f) => f.hasError).firstOrNull?.ensureVisible();
  }

  void saveFields() {
    _log("saveFields");
    for (final LnFormFieldState field in _fields) {
      field.controller.save();
    }
  }

  void clearFields() {
    _log("clearFields");
    _triedToValidate = false;
    for (final LnFormFieldState field in _fields) {
      field.controller.clear();
    }
  }

  void restoreFields() {
    _log("restoreFields");
    _triedToValidate = false;
    for (final LnFormFieldState field in _fields) {
      field.controller.restore();
    }
  }

  void _log(String functionName) {
    if (kLoggingEnabled) {
      FormLog.d("[FORM]", functionName, 2, fieldName: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      onFocusChange: null,
      child: widget.child,
    );
  }
}

class LnFormState<R> extends LnFormFieldsHostState<R> with LnFormActions<R> {
  @override
  Widget build(BuildContext context) {
    Widget child = super.build(context);

    if (widget.showUnsavedChangesMark) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (hasUnsavedChanges)
            Positioned(
              right: 0,
              child: _buildRotatedUnsavedText(context),
            ),
        ],
      );
    }

    return _LnFormScope(
      state: this,
      child: child,
    );
  }
}
