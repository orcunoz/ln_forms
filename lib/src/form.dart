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
import 'package:universal_platform/universal_platform.dart';

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

typedef WrapperBuilder = Widget Function(BuildContext context, Widget child);

enum AutovalidateMode {
  disabled,
  alwaysAfterFirst,
  always,
}

class LnForm<R> extends EditablePropsWidget
    implements UnsavedChangesNotifiableWidget {
  LnForm({
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    this.notifyProgressState = false,
    this.notifySuccessAlerts = false,
    this.notifyErrorAlerts = false,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.alwaysAfterFirst,
    required this.child,
    this.wrapperBuilder,
    //this.scrollable = true,
    this.controller,
    this.showUnsavedChangesMark = false,
    this.notifyUnsavedChanges = false,
    this.onSubmit,
    this.onError,
  }) : super(key: ValueKey(controller));

  final VoidCallback? onChanged;

  final FutureOr<R> Function(LnFormController<R>)? onSubmit;
  final void Function(LnFormController<R>, dynamic, StackTrace)? onError;

  final bool showUnsavedChangesMark;

  final Widget child;
  final WrapperBuilder? wrapperBuilder;

  // Wrapper props-
  final bool notifyProgressState;
  final bool notifySuccessAlerts;
  final bool notifyErrorAlerts;

  final AutovalidateMode autovalidateMode;

  @override
  final bool notifyUnsavedChanges;

  final LnFormController<R>? controller;

  @override
  State<LnForm<R>> createState() =>
      (controller as _LnFormState<R>?) ?? _LnFormState<R>();

  static LnFormController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LnFormScope>();
    return scope?.controller;
  }

  static LnFormController of(BuildContext context) {
    final LnFormController? controller = maybeOf(context);
    assert(() {
      if (controller == null) {
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
    return controller!;
  }
}

abstract class LnFormFieldsHostState<R>
    extends EditableScopeWidgetEditableState<LnForm<R>>
    with UnsavedChangesNotifiableStateMixin<LnForm<R>> {
  bool _triedToValidate = false;
  final Set<LnFormFieldState> _fields = <LnFormFieldState>{};
  final Set<LnFormButtonState> _buttons = <LnFormButtonState>{};

  LnAlertsController? _alertController;
  LnAlertsController? get alertsController => _alertController;

  @override
  void onScopedEditableStateChanged() {
    super.onScopedEditableStateChanged();
    for (var field in _fields) {
      field.notifyEditableScopePropsChanged();
    }
  }

  @override
  void onComputedEditableStateChanged() {
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
    for (final LnFormFieldState field in _fields) {
      field.controller.clear();
      field.setPassed(false);
    }
    _triedToValidate = false;
  }

  void restoreFields() {
    _log("restoreFields");
    for (final LnFormFieldState field in _fields) {
      field.controller.restore();
      field.setPassed(false);
    }
    _triedToValidate = false;
  }

  void _log(String functionName) {
    if (kLoggingEnabled) {
      FormLog.d("[FORM]", functionName, 2, fieldName: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    /*Widget child = Builder(builder: (context) {
      _alertController = LnAlerts.of(context);
      return widget.child;
    });

    if (widget.wrapperBuilder != null) {
      child = widget.wrapperBuilder!(context, child);
    }*/

    /*if (widget._hasWrapper) {
      child = LnFormWrapper(
        padding: widget.padding ?? EdgeInsets.zero,
        margin: widget.margin ?? EdgeInsets.zero,
        card: widget.card ?? false,
        useSafeAreaForBottom: widget.useSafeAreaForBottom ?? false,
        alertHost: widget.alertHost ?? true,
        child: child,
      );
    }*/

    /*child = OverlimitScrollView(
      child: child,
    );*/

    return FocusScope(
      onFocusChange: null,
      child: widget.wrapperBuilder != null
          ? widget.wrapperBuilder!(context, widget.child)
          : widget.child,
    );
  }
}

abstract class LnFormController<R> extends LnFormFieldsHostState<R> {
  factory LnFormController() => _LnFormState<R>();
  LnFormController._();

  FormAction get submit;
  FormAction get restore;
  FormAction get clear;
  FormAction get enableEditing;
  FormAction get cancelEditing;

  final _changeNotifier = ChangeNotifier();
  Listenable get listenable => _changeNotifier;

  @override
  void handleFieldValueChanged() {
    super.handleFieldValueChanged();
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    _changeNotifier.notifyListeners();
  }
}

class _LnFormState<R> extends LnFormController<R> with LnFormActions<R> {
  _LnFormState() : super._();

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
      controller: this,
      child: child,
    );
  }
}
