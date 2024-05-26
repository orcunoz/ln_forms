import 'dart:async';

import 'package:ln_core/ln_core.dart';

import 'editable_scope.dart';
import 'form.dart';

typedef FormActionCallable<R> = FutureOr<R?> Function();

class FormAction<R> {
  const FormAction({
    required LnFormState<R> form,
    required FormActionCallable<R>? callable,
    bool Function()? checkEnabled,
  })  : _form = form,
        _callable = callable,
        _checkEnabled = checkEnabled;

  final LnFormState<R> _form;
  final FormActionCallable<R>? _callable;
  final bool Function()? _checkEnabled;

  bool get enabled =>
      _callable != null &&
      _form.computedState.enabled &&
      (_checkEnabled == null || _checkEnabled!());

  FormActionCallable? get callable => enabled ? call : null;

  FutureOr<R?> call() {
    final futureOr = _callable!();
    if (futureOr is Future<R>) {
      _form._addRunningAction(this);
      return futureOr..whenComplete(() => _form._removeRunningAction(this));
    } else {
      return futureOr;
    }
  }
}

mixin LnFormActions<R> on LnFormFieldsHostState<R> {
  final Set<FormAction> _runningActions = <FormAction>{};
  bool get inProgress => _runningActions.isNotEmpty;

  @override
  EditableProps get editableProps => inProgress
      ? super.editableProps.apply(enabled: Value(false))
      : super.editableProps;

  bool isActionInProgress(FormAction action) =>
      _runningActions.contains(action);

  void _addRunningAction(FormAction action) {
    bool empty = _runningActions.isEmpty;
    bool added = _runningActions.add(action);
    if (empty && added) {
      notifyEditablePropsChanged();
    }
  }

  void _removeRunningAction(FormAction action) {
    bool last = _runningActions.length == 1;
    bool removed = _runningActions.remove(action);
    if (last && removed) {
      notifyEditablePropsChanged();
    }
  }

  /*late final enableEditing = FormAction(
    form: this as LnFormState<R>,
    checkEnabled: () => computedState.readOnly,
    callable: () {
      Log.w("enableEditing");
      readOnly = false;
    },
  );

  late final cancelEditing = FormAction(
    form: this as LnFormState<R>,
    checkEnabled: () => !computedState.readOnly,
    callable: () {
      readOnly = true;
    },
  );*/

  late final clear = FormAction(
    form: this as LnFormState<R>,
    checkEnabled: () => !isEmpty,
    callable: clearFields,
  );

  late final restore = FormAction(
    form: this as LnFormState<R>,
    checkEnabled: () => hasUnsavedChanges,
    callable: restoreFields,
  );

  late final submit = FormAction<R>(
    form: this as LnFormState<R>,
    callable: () {
      if (!validate()) {
        return Future.delayed(Duration(milliseconds: 300), () {
          ensureVisibleErrorField();
          return;
        });
        /*throw UserFriendlyAlert(
            type: AlertType.error,
            message: LnFormsLocalizations.current.pleaseFixValidationErrors,
          );*/
      }

      return widget.onSubmit!(this as LnFormState<R>);
    },
  );
}
