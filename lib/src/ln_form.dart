import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/src/utils/logger.dart';
import 'copyable.dart';

enum FormMode { view, edit }

enum ButtonsLocation { bottomAppBar, afterFields }

class LnFormActionButton {
  final String text;
  final Widget icon;
  final void Function()? onPressed;

  const LnFormActionButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  Widget build({
    required BuildContext context,
    required bool short,
    required bool primary,
    FocusNode? focusNode,
  }) {
    if (short) {
      if (primary) {
        return IconButton.filled(
          onPressed: onPressed,
          icon: icon,
          tooltip: text,
          focusNode: focusNode,
        );
      } else {
        final theme = Theme.of(context);
        return IconButton(
          onPressed: onPressed,
          icon: icon,
          tooltip: text,
          focusNode: focusNode,
          style: (theme.iconButtonTheme.style ?? ButtonStyle())
              .copyWith(iconColor: theme.colorScheme.primary.material),
        );
      }
    } else {
      if (primary) {
        return FilledButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(text),
          focusNode: focusNode,
        );
      } else {
        final theme = Theme.of(context);
        return TextButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: Text(text),
          focusNode: focusNode,
          style: (theme.iconButtonTheme.style ?? ButtonStyle())
              .copyWith(iconColor: theme.colorScheme.primary.material),
        );
      }
    }
  }
}

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

  final List<FocusNode> _focusNodes = [FocusNode(), FocusNode(), FocusNode()];

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
    for (var fn in _focusNodes) {
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
    String? cancelEditingButtonText,
    IconData cancelEditingButtonIcon,
  ) {
    final modeActionButtons =
        widget.modeActionButtons[_editMode ? FormMode.edit : FormMode.view] ??
            [];

    return <Widget>[
      for (var buttonData in modeActionButtons)
        buttonData.build(context: context, short: false, primary: true),
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
    String? cancelEditingButtonText,
    IconData cancelEditingButtonIcon,
  ) {
    final modeActionButtons = _editMode
        ? [
            if (widget.modeActionButtons[FormMode.edit] != null)
              ...widget.modeActionButtons[FormMode.edit]!,
            if (modes.contains(FormMode.view) ||
                widget.onClickCancelEditing != null)
              LnFormActionButton(
                onPressed: !enabled
                    ? null
                    : widget.onClickCancelEditing ??
                        () => changeMode(FormMode.view),
                icon: Icon(cancelEditingButtonIcon),
                text: cancelEditingButtonText ??
                    MaterialLocalizations.of(context).cancelButtonLabel,
              )
          ]
        : widget.modeActionButtons[FormMode.view] ?? [];

    return <Widget>[
      for (var button in modeActionButtons)
        button.build(context: context, short: true, primary: false),
      Expanded(child: SizedBox()),
      if (formMode == FormMode.edit) ...[
        if (onSubmitPressed != null)
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
                    _focusNodes[1].requestFocus();
                    onSubmitPressed();
                  }
                : null,
            focusNode: _focusNodes[1],
          ),
      ] else ...[
        if (modes.contains(FormMode.edit))
          _buildFloatingActionButton(
            icon: ProgressIndicatorIcon(
              icon: editButtonIcon,
              loading: !enabled,
            ),
            tooltip: editButtonText ?? "Düzenle",
            text: editButtonText ?? "Düzenle",
            onPressed: () => changeMode(FormMode.edit),
            focusNode: _focusNodes[2],
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
        widget.cancelEditingButtonText,
        widget.cancelEditingButtonIcon,
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

  Widget _buildBottomAppBar() {
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
      widget.cancelEditingButtonText,
      widget.cancelEditingButtonIcon,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.translationValues(
          0, _bottomAppBarIsVisible ? 0 : kToolbarHeight, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: .5, thickness: .5),
          BottomAppBar(
            padding: EdgeInsets.symmetric(vertical: 8),
            elevation: .0,
            height: kToolbarHeight,
            clipBehavior: Clip.antiAlias,
            child: _buildResponsiveContainer(
              child: Row(children: actionButtons),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContainer({
    bool card = false,
    Alignment alignment = Alignment.topCenter,
    required Widget child,
  }) {
    EdgeInsets margin = widget.margin +
        (widget.useSafeAreaForBottom
            ? MediaQuery.of(context).safeBottomPadding
            : EdgeInsets.zero);
    return Responsive(
      alignment: alignment,
      //padding: widget.padding.symetricScale(vertical: 0),
      margin: margin.symetricScale(vertical: 0),
      card: card,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Responsive(
      padding: widget.padding,
      margin: widget.margin +
          (widget.useSafeAreaForBottom
              ? MediaQuery.of(context).safeBottomPadding
              : EdgeInsets.zero) +
          (widget.buttonsLocation == ButtonsLocation.bottomAppBar
              ? EdgeInsets.only(bottom: kToolbarHeight)
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
      child = Stack(
        children: [
          AnimatedContainer(
            transform: Matrix4.translationValues(0, _translationY ?? 0, 0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: child,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomAppBar(),
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
