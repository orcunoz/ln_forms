import 'dart:async';

import 'editable_scope.dart';
import 'form.dart';
import 'localization/forms_localizations.dart';

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

  String get defaultButtonText {
    final localizations = LnFormsLocalizations.of(_form.context);

    if (this == _form.enableEditing) {
      return localizations.editButton;
    } else if (this == _form.cancelEditing) {
      return localizations.cancelButton;
    } else if (this == _form.submit) {
      return localizations.saveButton;
    } else if (this == _form.restore) {
      return localizations.restoreButton;
    } else if (this == _form.clear) {
      return localizations.resetButton;
    } else {
      return localizations.okButton;
    }
  }

  FutureOr<R?> call() {
    if (!enabled) return null;

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
  EditableProps get scopedState => inProgress
      ? super.scopedState.copyWith(enabled: (false,))
      : super.scopedState;

  bool isActionInProgress(FormAction action) =>
      _runningActions.contains(action);

  void _addRunningAction(FormAction action) {
    bool empty = _runningActions.isEmpty;
    bool added = _runningActions.add(action);
    if (empty && added) {
      didScopedEditableStateChanged();
    }
  }

  void _removeRunningAction(FormAction action) {
    bool last = _runningActions.length == 1;
    bool removed = _runningActions.remove(action);
    if (last && removed) {
      didScopedEditableStateChanged();
    }
  }

  late final enableEditing = FormAction(
    form: this as LnFormState<R>,
    checkEnabled: () => computedState.readOnly,
    callable: () {
      readOnly = false;
    },
  );

  late final cancelEditing = FormAction(
    form: this as LnFormState<R>,
    checkEnabled: () => !computedState.readOnly,
    callable: () {
      readOnly = true;
    },
  );

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
