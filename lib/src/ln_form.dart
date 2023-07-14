import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/src/utils/logger.dart';
import 'copyable.dart';
import 'ln_form_action_button.dart';

export 'ln_form_action_button.dart';

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
  final List<FormMode> modes;
  final FormMode initialMode;
  final ButtonsLocation buttonsLocation;
  final String? title;

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

  final Map<FormMode, List<LnFormActionButton>> modeActionButtons;

  final bool scrollable;
  final bool useSafeAreaForBottom;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool card;

  const LnForm({
    super.key,
    required this.fieldsBuilder,
    this.loading = false,
    required this.initialData,
    this.error,
    this.submitAction,
    this.modes = const [FormMode.view, FormMode.edit],
    this.initialMode = FormMode.view,
    this.buttonsLocation = ButtonsLocation.afterFields,
    this.title,
    this.successResultAutoCleanerDuration = const Duration(seconds: 5),
    this.errorResultAutoCleanerDuration = const Duration(seconds: 5),
    this.resetOnSuccess = true,
    this.saveOnSuccess = false,
    this.resetOnError = false,
    this.submitButtonText,
    this.submitButtonIcon = Icons.save_outlined,
    this.editButtonText,
    this.editButtonIcon = Icons.edit_note_rounded,
    this.cancelEditingButtonText,
    this.cancelEditingButtonIcon = Icons.arrow_back_rounded,
    this.onClickCancelEditing,
    this.modeActionButtons = const {},
    this.scrollable = true,
    this.useSafeAreaForBottom = true,
    this.padding = formPadding,
    this.margin = formMargin,
    this.card = true,
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

  void _listen() {
    final scrollDirectionIsForward =
        _scrollController!.position.userScrollDirection ==
            ScrollDirection.forward;
    if (scrollDirectionIsForward == _bottomAppBarIsVisible) {
      _bottomAppBarIsVisible = !scrollDirectionIsForward;
      _rebuild();
    }
  }

  _log(String functionName) {
    Log.form("#$_generation[FORM]", functionName, 2, fieldName: null);
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
      _scrollController = ScrollController()..addListener(_listen);
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_listen);
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
    _editMode = widget.modes.contains(FormMode.edit) &&
        (widget.initialMode == FormMode.edit ||
            !widget.modes.contains(FormMode.view));
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
    final modeActionButtons =
        widget.modeActionButtons[_editMode ? FormMode.edit : FormMode.view] ??
            [];

    final focusNodes = _getActionButtonFocusNodes(modeActionButtons.length + 1);

    return <Widget>[
      for (var (index, buttonData) in modeActionButtons.indexed)
        buttonData.build(
          context: context,
          short: false,
          primary: true,
          enabled: enabled,
          busy: false,
          focusNode: focusNodes[index + 1],
        ),
      if (formMode == FormMode.edit && onSubmitPressed != null) ...[
        ProgressIndicatorButton(
          onPressed: () {
            focusNodes[0].requestFocus();
            onSubmitPressed();
          },
          icon: submitButtonIcon,
          labelText: submitButtonText ??
              MaterialLocalizations.of(context).saveButtonLabel,
          loading: !enabled,
          focusNode: focusNodes[0],
        ),
      ],
      if (formMode == FormMode.view && modes.contains(FormMode.edit)) ...[
        ProgressIndicatorButton(
          onPressed: () => changeMode(FormMode.edit),
          icon: editButtonIcon,
          labelText: editButtonText ?? "Düzenle", // TODO
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
    final modeActionButtons =
        widget.modeActionButtons[_editMode ? FormMode.edit : FormMode.view] ??
            [];

    final focusNodes = _getActionButtonFocusNodes(modeActionButtons.length + 1);

    return <Widget>[
      for (var (index, buttonData) in modeActionButtons.indexed)
        buttonData.build(
          context: context,
          short: true,
          primary: false,
          enabled: enabled,
          busy: false,
          focusNode: focusNodes[index + 1],
        ),
      if (formMode == FormMode.edit && onSubmitPressed != null) ...[
        Expanded(child: SizedBox()),
        _buildFloatingActionButton(
          icon: ProgressIndicatorIcon(
            icon: submitButtonIcon,
            loading: !enabled,
          ),
          tooltip: MaterialLocalizations.of(context).saveButtonLabel,
          text: submitButtonText ??
              MaterialLocalizations.of(context).saveButtonLabel,
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
          tooltip: editButtonText ?? "Düzenle",
          text: editButtonText ?? "Düzenle",
          onPressed: () => changeMode(FormMode.edit),
          focusNode: focusNodes[0],
        ),
      ],
    ];
  }

  _setCleanerForResultState(final dynamic result, Duration duration) async {
    await Future.delayed(const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (result == _submitActionResult) {
        _submitActionResult = null;
      }
      if (result == _submitActionError) {
        _submitActionError = null;
      }
      _rebuild();
    });
  }

  Widget _buildForm() {
    final results = _buildResults(
        context, _data, widget.error, _submitActionResult, _submitActionError);

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
        actionsContainer = Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: actionButtons,
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
          if (results != null) results,
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
      return;
    }

    _loadingSubmitAction = true;
    _rebuild();

    try {
      final submitResult = await widget.submitAction!(_data!);

      if (widget.saveOnSuccess) {
        _formKey.currentState!.save();
      }

      if (widget.successResultAutoCleanerDuration != null) {
        _setCleanerForResultState(
            submitResult, widget.successResultAutoCleanerDuration!);
      }
      if (widget.resetOnSuccess) resetForm();
      _submitActionResult = submitResult;
    } catch (error, stackTrace) {
      Log.e(error, stackTrace: stackTrace);
      _submitActionError = error;

      if (widget.errorResultAutoCleanerDuration != null) {
        _setCleanerForResultState(
            error, widget.errorResultAutoCleanerDuration!);
      }
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
      const animationDuration = Duration(milliseconds: 300);
      final bottomAppBar = _buildBottomAppBar();
      final showBar = _bottomAppBarIsVisible && bottomAppBar != null;
      child = Stack(
        children: [
          AnimatedContainer(
            transform: Matrix4.translationValues(0, _translationY ?? 0, 0),
            duration: animationDuration,
            curve: Curves.easeInOut,
            child: child,
            padding: EdgeInsets.only(bottom: showBar ? kToolbarHeight + .5 : 0),
          ),
          AnimatedPositioned(
            duration: animationDuration,
            height: kToolbarHeight,
            bottom: showBar ? 0 : -kToolbarHeight,
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
              height: kToolbarHeight,
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

enum LnFormSubmitResultType { succeed, failed }

abstract class LnFormSubmitResult {
  LnFormSubmitResultType get type;
  String? message;
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
