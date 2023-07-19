import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ln_alerts/ln_alerts.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_dialogs/ln_dialogs.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/utilities/logger.dart';
import 'locales/form_localizations.dart';

export 'form_action_button.dart';

enum FormMode { view, edit }

enum ButtonsLocation { bottomAppBar, afterFields }

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

  /// Available modes for form.
  ///
  /// First mode will be initial for this form
  final List<FormMode> modes;
  final ButtonsLocation buttonsLocation;
  final String? title;

  final bool resetOnSuccess;
  final bool saveOnSuccess;
  final bool resetOnError;
  final String? submitButtonText;
  final IconData submitButtonIcon;
  final String? editButtonText;
  final IconData editButtonIcon;

  final List<LnFormActionButton> actionButtons;

  final bool scrollable;
  final bool useSafeAreaForBottom;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool card;
  final bool manageSuccessAlerts;
  final bool manageErrorAlerts;

  const LnForm({
    super.key,
    required this.fieldsBuilder,
    this.loading = false,
    required this.initialData,
    this.error,
    this.submitAction,
    this.modes = const [FormMode.view, FormMode.edit],
    this.buttonsLocation = ButtonsLocation.afterFields,
    this.title,
    this.resetOnSuccess = true,
    this.saveOnSuccess = false,
    this.resetOnError = false,
    this.submitButtonText,
    this.submitButtonIcon = Icons.save_outlined,
    this.editButtonText,
    this.editButtonIcon = Icons.edit_note_rounded,
    this.actionButtons = const [],
    this.scrollable = true,
    this.useSafeAreaForBottom = true,
    this.padding = formPadding,
    this.margin = formMargin,
    this.card = true,
    this.manageSuccessAlerts = true,
    this.manageErrorAlerts = true,
  }) : assert(modes.length > 0);

  @override
  State<LnForm<FormD, SubmitResultD>> createState() =>
      LnFormState<FormD, SubmitResultD>();
}

class LnFormState<FormD extends Copyable<FormD>, SubmitResultD>
    extends State<LnForm<FormD, SubmitResultD>> {
  int _generation = 0;
  FormD? _savedInitialData;
  FormD? _data;
  late GlobalKey<FormState> _formKey;
  late bool _editMode;
  ScrollController? _scrollController;
  SubmitResultD? _submitActionResult;
  Object? _submitActionError;
  bool _loadingSubmitAction = false;

  ScrollController? get scrollController => _scrollController;

  final List<FocusNode> _fns = <FocusNode>[];
  List<FocusNode> _getActionButtonFocusNodes(int requiredCount) {
    if (requiredCount > _fns.length) {
      var newNodes =
          List.generate(requiredCount - _fns.length, (index) => FocusNode());
      _fns.addAll(newNodes);
    }

    return _fns;
  }

  bool _bottomAppBarIsVisible = true;

  void _listenScroll() {
    final scrollDirectionIsForward =
        _scrollController!.position.userScrollDirection ==
            ScrollDirection.forward;
    if (scrollDirectionIsForward == _bottomAppBarIsVisible) {
      _bottomAppBarIsVisible = !scrollDirectionIsForward;
      _rebuild();
    }
  }

  _log(String functionName) {
    if (kLoggingEnabled) {
      FormLog.d("#$_generation[FORM]", functionName, 2, fieldName: null);
    }
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {
      ++_generation;
    });
  }

  @override
  void initState() {
    super.initState();
    _log("initState");
    _formKey = GlobalKey<FormState>();
    _savedInitialData = widget.initialData;
    resetForm();
    if (widget.scrollable) {
      _scrollController = ScrollController()..addListener(_listenScroll);
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_listenScroll);
    _scrollController?.dispose();
    for (var fn in _fns) {
      fn.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //_lastSubmittedData = widget.initialData?.copy();

    _log("didChangeDependencies");

    /*if (widget.initialData != _savedInitialData) {
        _savedInitialData = widget.initialData;
        _resetForm();
        _rebuild();
    }*/
  }

  @override
  void didUpdateWidget(covariant LnForm<FormD, SubmitResultD> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _log("didUpdateWidget");
  }

  void resetForm() {
    _data = _savedInitialData?.copy();
    _formKey.currentState?.reset();
    _editMode = widget.modes.first == FormMode.edit;
  }

  void _changeMode(FormMode mode) {
    assert(widget.modes.contains(mode));
    if (mode == FormMode.view) {
      resetForm();
    }

    _editMode = mode == FormMode.edit;
    _rebuild();

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

  /*static Widget? _buildResults<FormD, SubmitResultD>(
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
  }*/

  List<Widget> _buildActionButtons(
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
  ) {
    final focusNodes =
        _getActionButtonFocusNodes(widget.actionButtons.length + 1);
    final ss = formLocalizations.current;

    return <Widget>[
      for (var (index, buttonData) in widget.actionButtons.indexed)
        buttonData.build(
          context: context,
          short: false,
          primary: true,
          enabled: enabled,
          busy: false,
          focusNode: focusNodes[index + 1],
          onPressed: switch (buttonData.type) {
            LnFormActionButtonType.clear => () => ConfirmationDialog.show(
                  context: context,
                  message: ss
                      .areYouSureYouWantToX(ss.clearX(ss.formFields))
                      .sentenceCase,
                  onSubmit: () {
                    FocusScope.of(context).unfocus();

                    resetForm();
                    scrollController?.animateTo(0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                  },
                ),
            LnFormActionButtonType.restore => () => ConfirmationDialog.show(
                  context: context,
                  message:
                      ss.areYouSureYouWantToX(ss.restoreChanges).sentenceCase,
                  onSubmit: resetForm,
                ),
            _ => null,
          },
        ),
      if (formMode == FormMode.edit && onSubmitPressed != null) ...[
        ProgressIndicatorButton(
          onPressed: () {
            focusNodes[0].requestFocus();
            onSubmitPressed();
          },
          icon: submitButtonIcon,
          labelText: submitButtonText ?? formLocalizations.current.saveButton,
          loading: !enabled,
          focusNode: focusNodes[0],
        ),
      ],
      if (formMode == FormMode.view && modes.contains(FormMode.edit)) ...[
        ProgressIndicatorButton(
          onPressed: () => changeMode(FormMode.edit),
          icon: editButtonIcon,
          labelText: editButtonText ?? formLocalizations.current.editButton,
          loading: !enabled,
          focusNode: focusNodes[0],
        ),
      ],
    ];
  }

  List<Widget> _buildBottomAppBarActionButtons(
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
  ) {
    final focusNodes =
        _getActionButtonFocusNodes(widget.actionButtons.length + 1);
    final ss = formLocalizations.current;

    return <Widget>[
      for (var (index, buttonData) in widget.actionButtons.indexed)
        if (buttonData.enabledModes.contains(formMode))
          buttonData.build(
            context: context,
            short: false,
            primary: false,
            enabled: enabled,
            busy: false,
            focusNode: focusNodes[index + 1],
            onPressed: switch (buttonData.type) {
              LnFormActionButtonType.clear => () => ConfirmationDialog.show(
                    context: context,
                    message: ss
                        .areYouSureYouWantToX(ss.clearX(ss.formFields))
                        .sentenceCase,
                    onSubmit: () {
                      FocusScope.of(context).unfocus();

                      resetForm();
                      scrollController?.animateTo(0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut);
                    },
                  ),
              LnFormActionButtonType.restore => () => ConfirmationDialog.show(
                    context: context,
                    message:
                        ss.areYouSureYouWantToX(ss.restoreChanges).sentenceCase,
                    onSubmit: resetForm,
                  ),
              _ => null,
            },
          ),
      if (formMode == FormMode.edit && onSubmitPressed != null) ...[
        Expanded(child: SizedBox()),
        _buildFloatingActionButton(
          icon: ProgressIndicatorIcon(
            icon: submitButtonIcon,
            loading: !enabled,
          ),
          tooltip: formLocalizations.current.saveButton,
          text: submitButtonText ?? formLocalizations.current.saveButton,
          onPressed: enabled
              ? () {
                  focusNodes[0].requestFocus();
                  onSubmitPressed();
                }
              : null,
          focusNode: focusNodes[0],
        ),
      ],
      if (formMode == FormMode.view && modes.contains(FormMode.edit)) ...[
        Expanded(child: SizedBox()),
        _buildFloatingActionButton(
          icon: ProgressIndicatorIcon(
            icon: editButtonIcon,
            loading: !enabled,
          ),
          tooltip: editButtonText ?? formLocalizations.current.editButton,
          text: editButtonText ?? formLocalizations.current.editButton,
          onPressed: () => changeMode(FormMode.edit),
          focusNode: focusNodes[0],
        ),
      ],
    ];
  }

  Widget _buildForm() {
    /*final results = _buildResults(
        context, _data, widget.error, _submitActionResult, _submitActionError);*/

    Widget? actionsContainer;
    if (widget.buttonsLocation == ButtonsLocation.afterFields) {
      final actionButtons = _buildActionButtons(
        context,
        _editMode ? FormMode.edit : FormMode.view,
        widget.modes,
        !widget.loading && !_loadingSubmitAction,
        _changeMode,
        _data != null && widget.submitAction != null ? _onSubmitPressed : null,
        widget.submitButtonText,
        widget.submitButtonIcon,
        widget.editButtonText,
        widget.editButtonIcon,
      );

      if (actionButtons.isNotEmpty) {
        actionsContainer = Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 8,
            children: actionButtons,
          ),
        );
      }
    }

    return Form(
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
          //if (results != null) results,
          if (actionsContainer != null) actionsContainer,
        ],
      ),
    );
  }

  Future _onSubmitPressed() async {
    var valid = _formKey.currentState!.validate();
    if (!valid) {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
      _rebuild();
      return;
    }

    _loadingSubmitAction = true;
    _rebuild();

    try {
      var future = widget.submitAction!(_data!);
      if (widget.manageSuccessAlerts && widget.manageErrorAlerts) {
        future = future.manageAlerts(context);
      } else if (widget.manageSuccessAlerts) {
        future = future.manageSuccessAlerts(context);
      } else if (widget.manageErrorAlerts) {
        future = future.manageErrorAlerts(context);
      }

      final submitResult = await future;

      if (widget.modes.contains(FormMode.view)) {
        _changeMode(FormMode.view);
      }

      if (widget.saveOnSuccess) {
        _formKey.currentState!.save();
      }

      if (widget.resetOnSuccess) resetForm();
      _submitActionResult = submitResult;
    } catch (error, stackTrace) {
      Log.e(error, stackTrace: stackTrace);
      _submitActionError = error;

      if (widget.resetOnError) resetForm();
    } finally {
      _loadingSubmitAction = false;
      _rebuild();
    }
  }

  Widget _buildFloatingActionButton({
    Widget? icon,
    String? text,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    Function()? onPressed,
    bool visibility = true,
    FocusNode? focusNode,
  }) {
    assert(icon != null || text != null);
    final textWidget = text == null ? null : Text(text);
    final elevation = visibility ? 0.0 : null;
    final Widget button;
    if (textWidget == null) {
      button = FloatingActionButton(
        elevation: elevation,
        tooltip: tooltip,
        onPressed: onPressed,
        child: icon,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        focusNode: focusNode,
      );
    } else {
      button = FloatingActionButton.extended(
        elevation: elevation,
        tooltip: tooltip,
        onPressed: onPressed,
        label: textWidget,
        icon: icon,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        focusNode: focusNode,
      );
    }
    return button;
  }

  Widget? _buildBottomAppBar() {
    final actionButtons = _buildBottomAppBarActionButtons(
      context,
      _editMode ? FormMode.edit : FormMode.view,
      widget.modes,
      !widget.loading && !_loadingSubmitAction,
      _changeMode,
      _data != null && widget.submitAction != null ? _onSubmitPressed : null,
      widget.submitButtonText,
      widget.submitButtonIcon,
      widget.editButtonText,
      widget.editButtonIcon,
    );

    return actionButtons.isNotEmpty
        ? BottomAppBar(
            padding: EdgeInsets.symmetric(vertical: 8),
            elevation: .0,
            clipBehavior: Clip.antiAlias,
            child: Responsive(
              alignment: Alignment.topCenter,
              margin: widget.margin.symetricScale(vertical: 0),
              child: Row(children: actionButtons),
            ),
          )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    formLocalizations.of(context);
    validatorLocalizations.of(context);

    Widget child = Responsive(
      padding: widget.padding,
      margin: widget.margin +
          (widget.useSafeAreaForBottom
              ? MediaQuery.of(context).safeBottomPadding
              : EdgeInsets.zero),
      card: widget.card,
      child: FocusScope(
        onFocusChange: (value) {
          //_log("FocusScope.onFocusChange $value");
        },
        child: _buildForm(),
      ),
    );

    assert(!widget.scrollable || _scrollController != null);
    if (widget.scrollable) {
      child = PrimaryScrollController(
        controller: _scrollController!,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: child,
        ),
      );
    }

    if (widget.buttonsLocation == ButtonsLocation.bottomAppBar) {
      final barHeight =
          kToolbarHeight + MediaQuery.of(context).safeBottomPadding.bottom;
      const animationDuration = Duration(milliseconds: 300);
      final bottomAppBar = _buildBottomAppBar();
      final showBar = _bottomAppBarIsVisible && bottomAppBar != null;
      child = Stack(
        children: [
          AnimatedContainer(
            transform: Matrix4.translationValues(0, _translationY ?? 0, 0),
            duration: animationDuration,
            curve: Curves.easeInOut,
            padding: EdgeInsets.only(bottom: showBar ? kToolbarHeight + .5 : 0),
            child: child,
          ),
          AnimatedPositioned(
            duration: animationDuration,
            height: barHeight,
            bottom: showBar ? 0 : -barHeight,
            right: 0,
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: .5,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              height: barHeight,
              child: bottomAppBar,
            ),
          ),
        ],
      );
    }

    return LnFormFocusTarget(
      scrollController: _scrollController,
      setTranslationY: (double? y) {
        _translationY = y;
        _rebuild();
      },
      child: child,
    );
  }

  double? _translationY;
}

class LnFormFocusTarget extends InheritedWidget {
  final ScrollController? scrollController;
  final Function(double?) setTranslationY;
  const LnFormFocusTarget({
    required this.scrollController,
    required this.setTranslationY,
    required super.child,
  });

  static LnFormFocusTarget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LnFormFocusTarget>();
  }

  @override
  bool updateShouldNotify(LnFormFocusTarget oldWidget) =>
      setTranslationY != oldWidget.setTranslationY ||
      scrollController != oldWidget.scrollController;
}
