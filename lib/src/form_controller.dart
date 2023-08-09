part of 'form.dart';

/*void _restoreConfirmation() => _form?.getConfirmationThen(
        LnFormsLocalizations.current
            .areYouSureYouWantToX(LnFormsLocalizations.current.restoreChanges)
            .sentenceCase,
        LnFormsLocalizations.current.confirmButton,
        () {},
      );

  void _clearConfirmation() => _form?.getConfirmationThen(
        LnFormsLocalizations.current
            .areYouSureYouWantToX(LnFormsLocalizations.current
                .clearX(LnFormsLocalizations.current.formFields))
            .sentenceCase,
        LnFormsLocalizations.current.confirmButton,
        () {},
      );

  void _unsavedChangesConfirmation() => _form?.getConfirmationThen(
      LnFormsLocalizations.current.unsavedChangesWarning.sentenceCase,
      LnFormsLocalizations.current.confirmButton,
      () {});*/

typedef OnSubmitAction = FutureOr<dynamic> Function(BuildContext);

class LnFormController<R> {
  final FutureOr<R> Function(LnFormController)? onSubmit;
  final void Function(LnFormController, R)? onSuccess;
  final void Function(LnFormController, dynamic, StackTrace)? onError;
  final bool progressOverlay;
  final bool successAlerts;
  final bool errorAlerts;

  _LnFormState? _form;
  LnAlertHostState? _alertHost;

  ScrollController? get scrollController => _form?.scrollController;

  int get unsavedFieldsCount => _form?.unsavedFieldsCount ?? 0;

  bool get enabled => _inheritState.enabled;
  set enabled(bool val) => _setInheritState(enabled: val);

  bool get readOnly => _inheritState.readOnly;
  set readOnly(bool val) => _setInheritState(readOnly: val);

  bool? get clearable => _inheritState.clearable;
  set clearable(bool? val) => _setInheritState(clearable: val);

  bool? get restoreable => _inheritState.restoreable;
  set restoreable(bool? val) => _setInheritState(restoreable: val);

  _InheritState _inheritState;

  void _setInheritState({
    bool? enabled,
    bool? readOnly,
    bool? clearable,
    bool? restoreable,
  }) {
    final oldState = _inheritState;
    _inheritState = _inheritState.copyWith(
      enabled: enabled,
      readOnly: readOnly,
      clearable: clearable,
      restoreable: restoreable,
    );

    if (oldState != _inheritState) {
      _form
        ?.._rebuildButtons()
        .._rebuildFields();
    }
  }

  bool get inProgress => _waitingFutures.isNotEmpty;

  final Set<FutureOr> _waitingFutures = <FutureOr>{};

  Future<T> _wait<T>(final FutureOr<T> Function() future) async {
    _waitingFutures.add(future);
    _form
      ?.._rebuildButtons()
      .._rebuildFields();
    var result = await future();

    _waitingFutures.remove(future);
    _form
      ?.._rebuildButtons()
      .._rebuildFields();
    return result;
  }

  LnFormController({
    this.onSubmit,
    this.onSuccess,
    this.onError,
    bool enabled = true,
    bool readOnly = false,
    bool? clearable,
    bool? restoreable,
    this.progressOverlay = false,
    this.successAlerts = true,
    this.errorAlerts = true,
  }) : _inheritState = _InheritState(
          enabled: enabled,
          readOnly: readOnly,
          clearable: clearable,
          restoreable: restoreable,
        );

  void _setFormContext(
    _LnFormState form,
    LnAlertHostState? alertHost,
  ) {
    _form = form;
    _alertHost = alertHost;
  }

  void save() => _form?._save();

  void reset() => _form?._reset();

  void clear() => reset();

  void restore() => reset();

  void scrollToTop() {
    scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  bool validate() {
    bool isValid = _form?._validate() != false;
    _form?._rebuild();
    return isValid;
  }

  void unfocus() {
    if (_form != null) FocusScope.of(_form!.context).unfocus();
  }

  FutureOr submit() async {
    final unique = "$_form";

    try {
      _alertHost?.removeByUnique(unique);

      final valid = validate();
      if (!valid) {
        await Future.delayed(Duration(milliseconds: 300));
        await _form?._fields.firstWhere((f) => !f.isValid).ensureVisible();
        throw UserFriendlyAlertData(
          type: AlertType.error,
          message: LnFormsLocalizations.current.pleaseFixValidationErrors,
        );
      }

      if (progressOverlay) {
        _alertHost?.addProgress(unique);
      }

      final result = await onSubmit!(this);
      if (successAlerts) {
        _alertHost?.show(LnAlert.successAutoDetect(result), unique: unique);
      }

      if (onSuccess != null) {
        onSuccess!(this, result);
      }
    } catch (error, stackTrace) {
      if (errorAlerts) {
        _alertHost?.show(LnAlert.errorAutoDetect(error), unique: unique);
      }

      if (onError != null) {
        onError!(this, error, stackTrace);
      }
    } finally {
      if (progressOverlay) {
        _alertHost?.removeProgress(unique);
      }
    }
  }

  static Future<bool> _getConfirmationThen(
          BuildContext context, String message, String? confirmButton) =>
      ConfirmationDialog.show(
        context: context,
        message: message,
        confirmButton: LnDialogButton.confirm(text: confirmButton),
      );

  static LnFormController? maybeOf(BuildContext context) =>
      _LnFormScope.maybeOf(context)?.controller;

  static LnFormController of(BuildContext context) {
    final LnFormController? formController = maybeOf(context);
    assert(() {
      if (formController == null) {
        throw FlutterError(
          'LnFormController.of() was called with a context that does not contain a LnForm widget.\n'
          'No LnForm widget ancestor could be found starting from the context that '
          'was passed to LnFormController.of(). This can happen because you are using a widget '
          'that looks for a Form ancestor, but no such ancestor exists.\n'
          'The context used was:\n'
          '  $context',
        );
      }
      return true;
    }());
    return formController!;
  }

  dispose() {
    _form = null;
    _alertHost = null;
  }
}
