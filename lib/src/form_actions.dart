import 'dart:async';

import 'package:ln_alerts/ln_alerts.dart';
import 'package:ln_core/ln_core.dart';

import 'editable_scope.dart';
import 'form.dart';
import 'localization/forms_localizations.dart';

typedef FormActionCallable = FutureOr Function(LnFormController);

class FormAction {
  const FormAction({
    required LnFormController formController,
    required FormActionCallable? callable,
    bool Function()? checkEnabled,
  })  : _form = formController as LnFormActions,
        _callable = callable,
        _checkEnabled = checkEnabled;

  final LnFormActions _form;
  final FormActionCallable? _callable;
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

  FutureOr call() async {
    if (enabled) {
      FutureOr<dynamic> futureOr;
      try {
        futureOr = _callable!(_form);

        if (futureOr is Future) {
          _form._addRunningAction(this);
          return await futureOr;
        } else {
          return futureOr;
        }
      } catch (_) {
        rethrow;
      } finally {
        if (futureOr is Future) {
          _form._removeRunningAction(this);
        }
      }
    }
  }
}

mixin LnFormActions<R> on LnFormController<R> {
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
      onScopedEditableStateChanged();
    }
  }

  void _removeRunningAction(FormAction action) {
    bool last = _runningActions.length == 1;
    bool removed = _runningActions.remove(action);
    if (last && removed) {
      onScopedEditableStateChanged();
    }
  }

  @override
  late final enableEditing = FormAction(
    formController: this as LnFormController<R>,
    checkEnabled: () => computedState.readOnly,
    callable: (_) {
      readOnly = false;
    },
  );

  @override
  late final cancelEditing = FormAction(
    formController: this,
    checkEnabled: () => !computedState.readOnly,
    callable: (_) {
      readOnly = true;
    },
  );

  @override
  late final clear = FormAction(
    formController: this as LnFormController<R>,
    checkEnabled: () => !isEmpty,
    callable: (c) => c.clear(),
  );

  @override
  late final restore = FormAction(
    formController: this as LnFormController<R>,
    checkEnabled: () => hasUnsavedChanges,
    callable: (c) => c.restore(),
  );

  @override
  late final submit = FormAction(
    formController: this as LnFormController<R>,
    callable: (_) async {
      final unique = "$this.submit";
      //Log.fatal("1 - $unique");
      late LnAlertsController alertsController;

      try {
        if (widget.notifySuccessAlerts ||
            widget.notifyErrorAlerts ||
            widget.notifyProgressState) {
          alertsController = this.alertsController ?? LnAlerts.of(context);
          alertsController.removeAlert(unique);
        }

        //Log.fatal("2");
        if (!validate()) {
          await Future.delayed(Duration(milliseconds: 300));
          await ensureVisibleErrorField();
          throw UserFriendlyAlert(
            type: AlertType.error,
            message: LnFormsLocalizations.current.pleaseFixValidationErrors,
          );
        }

        //Log.fatal("3");
        if (widget.notifyProgressState) {
          //Log.fatal("3.1 notifyProgress: true");
          alertsController.notifyProgressing(true, unique);
        }

        //Log.fatal("4");
        final result = await widget.onSubmit!(this);
        if (widget.notifySuccessAlerts) {
          alertsController.show(
            LnAlert.successAutoDetect(result),
            unique: unique,
          );
        }

        //Log.fatal("5");
        return result;
      } catch (error, stackTrace) {
        Log.e(error, stackTrace: stackTrace);

        if (widget.onError != null) {
          widget.onError!(this, error, stackTrace);
        }

        if (widget.notifyErrorAlerts) {
          alertsController.show(
            LnAlert.errorAutoDetect(error),
            unique: unique,
          );
        } else {
          rethrow;
        }
      } finally {
        //Log.fatal("5-finally");
        if (widget.notifyProgressState) {
          //Log.fatal("5.1-finally notifyProgress: false");
          alertsController.notifyProgressing(false, unique);
        }
      }
    },
  );
}
