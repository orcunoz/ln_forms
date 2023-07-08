import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/src/utils/logger.dart';
import 'copyable.dart';

enum FormMode { view, edit }

typedef FieldsBuilder<FormD extends Copyable<FormD>, SubmitResultD>
    = List<Widget> Function(
  BuildContext context,
  void Function(VoidCallback) setState,
  FormD? data,
  SubmitResultD? submitResultData,
  Object? submitError,
  bool enabled,
  bool readOnly,
);

class LnForm<FormD extends Copyable<FormD>, SubmitResultD>
    extends StatefulWidget {
  final FieldsBuilder<FormD, SubmitResultD> fieldsBuilder;
  final FormD? initialData;
  final Object? error;
  final bool loading;
  final Future<SubmitResultD?> Function(FormD data)? submitAction;
  final bool scrollable;
  final bool useSafeAreaForBottom;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final List<FormMode> modes;
  final FormMode initialMode;
  final String? title;
  final bool card;

  /// Set null if you want to disable auto cleaner feature on succeed
  final Duration? successResultAutoCleanerDuration;

  /// Set null if you want to disable auto cleaner feature on failed
  final Duration? errorResultAutoCleanerDuration;

  final bool resetOnSuccess;
  final bool saveOnSuccess;
  final bool resetOnError;
  final String? submitButtonText;
  final IconData submitButtonIcon;
  final String? editButtonText;
  final IconData editButtonIcon;
  final String? cancelEditingButtonText;
  final IconData cancelEditingButtonIcon;
  final Function()? onClickCancelEditing;

  const LnForm({
    super.key,
    required this.fieldsBuilder,
    this.loading = false,
    required this.initialData,
    this.error,
    this.submitAction,
    this.scrollable = true,
    this.useSafeAreaForBottom = true,
    this.margin = formMargin,
    this.padding = formPadding,
    this.modes = const [FormMode.view, FormMode.edit],
    this.initialMode = FormMode.view,
    this.title,
    this.successResultAutoCleanerDuration = const Duration(seconds: 5),
    this.errorResultAutoCleanerDuration = const Duration(seconds: 5),
    this.resetOnSuccess = true,
    this.saveOnSuccess = false,
    this.resetOnError = false,
    this.submitButtonText,
    this.submitButtonIcon = Icons.save_rounded,
    this.editButtonText,
    this.editButtonIcon = Icons.edit_note_rounded,
    this.cancelEditingButtonText,
    this.cancelEditingButtonIcon = Icons.arrow_back_rounded,
    this.onClickCancelEditing,
    this.card = true,
  }) : assert(modes.length > 0);

  @override
  State<LnForm<FormD, SubmitResultD>> createState() =>
      LnFormState<FormD, SubmitResultD>();
}

class LnFormState<FormD extends Copyable<FormD>, SubmitResultD>
    extends State<LnForm<FormD, SubmitResultD>> {
  late FormD? _savedInitialData;
  late FormD? _data;
  late GlobalKey<FormState> _formKey;
  late bool _editMode;
  ScrollController? _scrollController;
  SubmitResultD? _submitActionResult;
  Object? _submitActionError;
  bool _loadingSubmitAction = false;

  final List<FocusNode> _focusNodes = [FocusNode(), FocusNode(), FocusNode()];

  _log(String functionName) {
    Log.formLog("[FORM]", functionName, 2, fieldName: null);
  }

  @override
  void initState() {
    super.initState();
    _log("form initState");
    _formKey = GlobalKey<FormState>();
    _savedInitialData = widget.initialData;
    _resetForm();
    if (widget.scrollable) {
      _scrollController = LnPrimaryScrollController(setState: setState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_lastSubmittedData = widget.initialData?.copy();

    _log(
        "didChangeDependencies -------------------------------------------------");

    /*if (widget.initialData != _savedInitialData) {
      setState(() {
        _savedInitialData = widget.initialData;
        _resetForm();
      });
    }*/
  }

  @override
  void didUpdateWidget(covariant LnForm<FormD, SubmitResultD> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _log("didUpdateWidget");
  }

  void _resetForm() {
    resetFunc() {
      _data = _savedInitialData?.copy();
      _formKey.currentState?.reset();
      //_formKey = GlobalKey<FormState>();
      _editMode = widget.modes.contains(FormMode.edit) &&
          (widget.initialMode == FormMode.edit ||
              !widget.modes.contains(FormMode.view));
    }

    if (mounted) {
      setState(resetFunc);
    } else {
      resetFunc();
    }
  }

  void _changeMode(FormMode mode) {
    assert(widget.modes.contains(mode));
    if (mode == FormMode.edit) {
      setState(() {
        _editMode = true;
      });
    } else if (mode == FormMode.view) {
      setState(() {
        _resetForm();
        _editMode = false;
      });
    }

    if (widget.scrollable) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  static Widget _buildTitle(BuildContext context, String title) {
    return Container(
      alignment: Alignment.topLeft,
      child: Text(
        title,
        style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor),
      ),
    );
  }

  static Widget? _buildResults<FormD, SubmitResultD>(
    BuildContext context,
    FormD? data,
    Object? widgetError,
    SubmitResultD? submitActionResult,
    Object? submitActionError,
  ) {
    var results = [
      if (submitActionResult != null &&
          submitActionResult is LnFormSubmitResult)
        (submitActionResult.type == LnFormSubmitResultType.succeed
                ? ActionBox.success
                : ActionBox.error)
            .call(
          context: context,
          message: submitActionResult.message,
        ),
      if (submitActionError != null)
        ActionBox.errorAutoDetect(
          context: context,
          error: submitActionError,
        ),
      if (widgetError != null)
        ActionBox.errorAutoDetect(
          context: context,
          error: widgetError,
        ),
    ];

    return results.isEmpty ? null : SpacedColumn(children: results);
  }

  Widget? _buildActionButtons(
    BuildContext context,
    FormMode formMode,
    List<FormMode> modes,
    bool enabled,
    Function(FormMode) changeMode,
    Function()? onSubmitPressed,
    String? submitButtonText,
    IconData submitButtonIcon,
    String? editButtonText,
    IconData editButtonIcon,
    String? cancelEditingButtonText,
    IconData cancelEditingButtonIcon,
  ) {
    final actionButtons = [
      if (formMode == FormMode.edit) ...[
        if (modes.contains(FormMode.view) ||
            widget.onClickCancelEditing != null)
          FilledButton.icon(
            onPressed: !enabled
                ? null
                : widget.onClickCancelEditing ??
                    () => changeMode(FormMode.view),
            icon: Icon(cancelEditingButtonIcon),
            label: Text(cancelEditingButtonText ??
                MaterialLocalizations.of(context).cancelButtonLabel),
            focusNode: _focusNodes[0],
          ),
        if (onSubmitPressed != null)
          ProgressIndicatorButton(
            onPressed: () {
              _focusNodes[1].requestFocus();
              onSubmitPressed();
            },
            icon: submitButtonIcon,
            labelText: submitButtonText ??
                MaterialLocalizations.of(context).saveButtonLabel,
            loading: !enabled,
            focusNode: _focusNodes[1],
          ),
      ] else ...[
        if (modes.contains(FormMode.edit))
          ProgressIndicatorButton(
            onPressed: () => changeMode(FormMode.edit),
            icon: editButtonIcon,
            labelText: editButtonText ?? "Düzenle", // TODO
            loading: !enabled,
            focusNode: _focusNodes[2],
          ),
      ],
    ];

    return actionButtons.isEmpty
        ? null
        : SpacedRow(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actionButtons,
          );
  }

  _setCleanerForResultState(final dynamic result, Duration duration) {
    Future.delayed(
        const Duration(seconds: 5),
        () => Future.microtask(
              () => mounted
                  ? setState(() {
                      if (result == _submitActionResult) {
                        _submitActionResult = null;
                      }
                      if (result == _submitActionError) {
                        _submitActionError = null;
                      }
                    })
                  : null,
            ));
  }

  @override
  Widget build(BuildContext context) {
    final submitAction = widget.submitAction;
    final onSubmitPressed = _data == null || submitAction == null
        ? null
        : () {
            var valid = _formKey.currentState!.validate();
            if (valid) {
              setState(() {
                _loadingSubmitAction = true;
              });
              final future = submitAction(_data!).then((value) {
                if (mounted) {
                  setState(() {
                    if (widget.saveOnSuccess) {
                      _formKey.currentState!.save();
                    }
                    _loadingSubmitAction = false;

                    _submitActionResult = value;
                  });
                }

                if (widget.successResultAutoCleanerDuration != null) {
                  _setCleanerForResultState(
                      value, widget.successResultAutoCleanerDuration!);
                }
                if (widget.resetOnSuccess) _resetForm();
                return value;
              });

              future.onError((error, stackTrace) {
                Log.e(error, stackTrace: stackTrace);
                if (mounted) {
                  setState(() {
                    _submitActionError = error;
                    _loadingSubmitAction = false;
                  });
                }

                if (widget.errorResultAutoCleanerDuration != null) {
                  _setCleanerForResultState(
                      error, widget.errorResultAutoCleanerDuration!);
                }
                if (widget.resetOnError) _resetForm();
                return null;
              });
            }
          };

    final actionButtons = _buildActionButtons(
      context,
      _editMode ? FormMode.edit : FormMode.view,
      widget.modes,
      !widget.loading && !_loadingSubmitAction,
      _changeMode,
      onSubmitPressed,
      widget.submitButtonText,
      widget.submitButtonIcon,
      widget.editButtonText,
      widget.editButtonIcon,
      widget.cancelEditingButtonText,
      widget.cancelEditingButtonIcon,
    );

    final results = _buildResults(
        context, _data, widget.error, _submitActionResult, _submitActionError);

    final mediaQuery = MediaQuery.of(context);

    Widget buildForm() => Responsive(
          padding: widget.padding,
          margin: widget.useSafeAreaForBottom
              ? widget.margin + mediaQuery.safeBottomPadding
              : widget.margin,
          card: widget.card,
          child: FocusScope(
            onFocusChange: (value) {
              //_log("FocusScope.onFocusChange $value");
            },
            child: Form(
              key: _formKey,
              child: Wrap(
                runSpacing: formVerticalSpacing,
                spacing: formHorizontalSpacing,
                alignment: WrapAlignment.center,
                children: [
                  if (widget.title != null) _buildTitle(context, widget.title!),
                  ...widget.fieldsBuilder(
                    context,
                    setState,
                    _data,
                    _submitActionResult,
                    _submitActionError,
                    !widget.loading && !_loadingSubmitAction,
                    !_editMode,
                  ),
                  if (results != null) results,
                  if (actionButtons != null) actionButtons,
                ],
              ),
            ),
          ),
        );

    Widget child = buildForm();

    assert(!widget.scrollable || _scrollController != null);
    if (widget.scrollable) {
      if (_scrollController is LnPrimaryScrollController) {
        final lnScrollController =
            _scrollController as LnPrimaryScrollController;
        child = AnimatedContainer(
          transform: Matrix4.translationValues(
              0,
              lnScrollController._additionalPadding.top -
                  lnScrollController._additionalPadding.bottom,
              0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: child,
        );
      }

      child = PrimaryScrollController(
        controller: _scrollController!,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: child,
        ),
      );
    }

    return child;
  }
}

enum LnFormSubmitResultType { succeed, failed }

abstract class LnFormSubmitResult {
  LnFormSubmitResultType get type;
  String? message;
}

class LnPrimaryScrollController extends ScrollController {
  // TODO
  void Function(VoidCallback) setState;
  EdgeInsets _additionalPadding = EdgeInsets.zero;
  LnPrimaryScrollController({
    required this.setState,
  });

  setAdditionalPadding(EdgeInsets padd) {
    setState(() {
      _additionalPadding = padd;
    });
  }

  @override
  String toString() {
    return "---- Debug: ${super.toString()}";
  }
}
