part of 'form.dart';

abstract class LnFormField<T> extends StatefulWidget {
  final T? initialValue;
  final TextStyle? style;
  final LnDecoration? decoration;
  final FocusNode? focusNode;
  final bool useFocusNode;
  final bool autofocus;

  final bool absorbInsideTapEvents;
  final bool handleTapOutsideWhenFocused;
  final bool unfocusWhenTapOutside;

  final void Function(T? newValue)? onSaved;
  final String? Function(T?)? validator;
  final Widget? Function(LnFormFieldState<T> state) builder;
  final void Function(T?)? onChanged;

  final String? restorationId;

  final bool? enabled;
  final bool? readOnly;
  final bool? clearable;
  final bool? restoreable;

  const LnFormField({
    required super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onSaved,
    required this.focusNode,
    required this.useFocusNode,
    this.autofocus = false,
    this.enabled,
    this.readOnly,
    this.clearable,
    this.restoreable,
    required this.validator,
    required this.style,
    required this.decoration,
    required this.builder,
    this.absorbInsideTapEvents = false,
    this.handleTapOutsideWhenFocused = false,
    this.unfocusWhenTapOutside = false,
    this.restorationId,
  });

  @override
  State<LnFormField<T>> createState() => LnFormFieldState<T>();
}

class LnFormFieldState<T> extends State<LnFormField<T>> with RestorationMixin {
  late T? _value = widget.initialValue;
  final RestorableStringN _errorText = RestorableStringN(null);

  ScopedState? _scopedState;
  ScopedState get scopedState => _scopedState!;

  T? get value => _value;
  String? get errorText => _errorText.value;
  bool get hasError => _errorText.value != null;
  bool get isValid => widget.validator?.call(_value) == null;

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_errorText, 'error_text');
  }

  T? _stateInitialValue;
  bool _focusedBefore = false;
  bool _isPassed = false;
  bool get isPassed => _isPassed;

  bool _isHovering = false;
  bool get isHovering => _isHovering;

  bool get isFocused => scopedState.active && effectiveFocusNode.hasFocus;

  bool get isEmpty => Validator.isEmptyValue(value);

  bool get unsaved =>
      _stateInitialValue != value &&
      !(Validator.isEmptyValue(_stateInitialValue) &&
          Validator.isEmptyValue(value));

  FocusNode? _internalNode;
  FocusNode get effectiveFocusNode => widget.focusNode ?? _internalNode!;

  TextStyle get baseTextStyle =>
      Theme.of(context).defaultFormFieldStyle.merge(widget.style);

  FocusNode? _editingActionButtonFocusNode;
  FocusNode get editingActionButtonFocusNode =>
      _editingActionButtonFocusNode ??=
          FocusNode(skipTraversal: true, canRequestFocus: true);

  Widget? get editingActionButton {
    if (scopedState.active && UniversalPlatform.isDesktopOrWeb
        ? isHovering
        : isFocused) {
      if (scopedState.restoreable && value != _stateInitialValue) {
        return IconButton(
          icon: const Icon(Icons.settings_backup_restore_rounded),
          focusNode: editingActionButtonFocusNode,
          onPressed: () => setValue(_stateInitialValue),
          //tooltip: S.current.restore,
        );
      } else if (scopedState.clearable && !isEmpty) {
        return IconButton(
          icon: const Icon(Icons.clear_rounded),
          focusNode: editingActionButtonFocusNode,
          onPressed: () => setValue(null),
          //tooltip: S.current.clear,
        );
      }
    }

    return null;
  }

  MouseCursor get effectiveMouseCursor => MouseCursor.defer;

  LnDecoration get baseDecoration => const LnDecoration();

  InputDecoration? _effectiveDecoration;
  InputDecoration get effectiveDecoration =>
      _effectiveDecoration ??= _prepareDecorationForBuild();

  InputDecoration _prepareDecorationForBuild() {
    LnDecoration decorationBase = (widget.decoration ?? const LnDecoration())
        .applyDefaults(baseDecoration);

    if (scopedState.readOnly) {
      decorationBase = decorationBase.apply(
        hint: Wrapped(null),
        counter: Wrapped(null),
        suffixIcon: Wrapped(null),
        error: Wrapped(null),
        helper: Wrapped(null),
      );
    }

    InputDecoration decoration = decorationBase
        .build()
        .applyDefaults(Theme.of(context).inputDecorationTheme)
        .copyWith(
          prefixIconConstraints: const BoxConstraints(
              minHeight: 36, minWidth: kMinInteractiveDimension),
          suffixIconConstraints: const BoxConstraints(
              minHeight: 36, minWidth: kMinInteractiveDimension),
        );

    if (scopedState.readOnly) {
      decoration = decoration.copyWith(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            decoration.contentPadding?.at(context).copyWith(left: 0, right: 0),
        filled: false,
        border: decoration.readOnlyBorder,
        errorBorder: decoration.readOnlyBorder,
        enabledBorder: decoration.readOnlyBorder,
        focusedBorder: decoration.readOnlyBorder,
        disabledBorder: decoration.readOnlyBorder,
        focusedErrorBorder: decoration.readOnlyBorder,
      );
    } else {
      decoration = decoration.copyWith(
        suffixIcon: editingActionButton ?? decoration.suffixIcon,
        errorText: isPassed ? errorText : null,
      );
    }

    /*decoration = decoration.copyWith(
      label: SpacedRow(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: decoration.label ?? Text(decoration.labelText ?? "")),
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [ElevationBoxShadow(1)],
            ),
          ),
        ],
      ),
    );*/

    return decoration;
  }

  @override
  Widget build(BuildContext context) {
    final form = _LnFormScope.maybeOf(context)?.._register(this);
    final controller = form?.controller;

    _scopedState = _InheritState(
      enabled: widget.enabled ?? true && controller?.inProgress != true,
      readOnly: widget.readOnly ?? false,
      clearable: widget.clearable,
      restoreable: widget.restoreable,
    ).scope(controller?._inheritState);

    if (!scopedState.active && effectiveFocusNode.hasFocus) {
      effectiveFocusNode.unfocus();
    }

    _effectiveDecoration = null;
    _validate();

    Widget child = isEmpty && scopedState.readOnly
        ? EmptyReadOnlyField(
            color: Theme.of(context).hintColor,
          )
        : widget.builder(this) ?? const SizedBox();

    child = DefaultTextStyle(
      style: baseTextStyle,
      child: child,
    );

    if (widget.absorbInsideTapEvents) {
      child = AbsorbPointer(
        child: child,
      );
    }

    if (widget.decoration != null) {
      InputDecoration decoration = effectiveDecoration;

      child = AnimatedBuilder(
        animation: effectiveFocusNode,
        builder: (BuildContext context, Widget? child) {
          return InputDecorator(
            textAlignVertical: TextAlignVertical.center,
            decoration: decoration,
            baseStyle: baseTextStyle,
            isHovering: isHovering,
            isFocused: isFocused,
            isEmpty: isEmpty,
            child: child,
          );
        },
        child: child,
      );
    }

    child = Opacity(
      opacity: scopedState.enabled ? 1 : 0.5,
      child: child,
    );

    if (widget.handleTapOutsideWhenFocused) {
      child = TapRegion(
        enabled: effectiveFocusNode.hasFocus,
        onTapOutside: (_) => handleTapOutside(),
        behavior: HitTestBehavior.opaque,
        debugLabel: 'InputFormField',
        child: child,
      );
    }

    child = MouseRegion(
      cursor: effectiveMouseCursor,
      onEnter: (_) => scopedState.active ? handleHover(true) : null,
      onExit: (_) =>
          scopedState.active || isHovering ? handleHover(false) : null,
      child: child,
    );

    child = Focus(
      canRequestFocus: scopedState.active,
      skipTraversal: widget.useFocusNode ? null : true,
      focusNode: widget.useFocusNode ? effectiveFocusNode : null,
      //parentNode: useFocusNode ? null : state.effectiveFocusNode,
      onFocusChange: handleFocusChanged,
      onKeyEvent: (node, event) => effectiveFocusNode.hasFocus
          ? handleKeyEvent(event)
          : KeyEventResult.ignored,
      child: child,
    );

    child = GestureDetector(
      onTap: () => scopedState.active ? handleTap() : null,
      child: child,
    );

    return child;
  }

  void _createInternalFocusNode() {
    assert(_internalNode == null);
    _internalNode = FocusNode();
  }

  void rebuild() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> ensureVisible() async {
    final scrollablePosition = Scrollable.maybeOf(context)?.position;
    if (scrollablePosition != null) {
      await context.findRenderObject()?.ensureVisible(scrollablePosition);
    }
  }

  @override
  void initState() {
    _log("initState");
    super.initState();

    _stateInitialValue = widget.initialValue;

    if (widget.focusNode == null) {
      _createInternalFocusNode();
    }

    /*effectiveFocusNode
      ..canRequestFocus = isActive
      ..addListener(_focusChangeListener)
      ..onKeyEvent = (node, event) =>
          (isActive ? handleKeyEvent(event) : KeyEventResult.ignored);*/
  }

  @override
  void didUpdateWidget(LnFormField<T> oldWidget) {
    _log("didUpdateWidget");
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      //unsyncFocusNode(oldWidget.focusNode);

      if (widget.focusNode == null) {
        _createInternalFocusNode();
      }

      //syncFocusNode(effectiveFocusNode);
    }

    /*if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }*/
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.initialValue != _stateInitialValue) {
      _log("didChangeDependencies -> initialValueChanged: "
          "${widget.initialValue?.toString().limitLength(30)}->"
          "${_stateInitialValue?.toString().limitLength(30)}");
    } else {
      _log("didChangeDependencies");
    }
  }

  @override
  void deactivate() {
    _LnFormScope.maybeOf(context)?._unregister(this);
    super.deactivate();
  }

  @override
  void dispose() {
    _log("dispose");
    _internalNode?.dispose();
    _editingActionButtonFocusNode?.dispose();
    super.dispose();
  }

  /*void _focusChangeListener() {
    handleFocusChanged(effectiveFocusNode.hasFocus);
  }*/

  void setValue(T? value) {
    if (this.value != value) {
      _log("setValue: $value");
      _value = value;
      rebuild();
      _LnFormScope.maybeOf(context)?._fieldDidChange();
      if (widget.onChanged != null) widget.onChanged!(value);
    }
  }

  @mustCallSuper
  void handleFocusChanged(bool hasFocus) {
    _log("handler -> focusChange: $hasFocus");

    if (hasFocus) {
      _focusedBefore = true;
    } else if (_focusedBefore) {
      if (!isFocused) {
        _isPassed = true;
      }
    }
    rebuild();
  }

  @mustCallSuper
  KeyEventResult handleKeyEvent(KeyEvent event) {
    assert(effectiveFocusNode.hasFocus);
    _log(
        "handler -> onKeyEvent(${event.runtimeType}): ${event.logicalKey.keyLabel}");

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      effectiveFocusNode.unfocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @mustCallSuper
  void handleTap() {
    assert(scopedState.active);
    _log("handler -> tap");
  }

  @mustCallSuper
  void handleTapOutside() {
    assert(scopedState.active && effectiveFocusNode.hasFocus);
    _log("handler -> tapOutside");
    if (widget.unfocusWhenTapOutside) {
      effectiveFocusNode.unfocus();
    }
  }

  @mustCallSuper
  void handleHover(bool hovering) {
    assert(scopedState.active || (_isHovering && !hovering));
    if (hovering == _isHovering) return;
    _log("handler -> hover: $hovering");

    _isHovering = hovering;
    rebuild();
  }

  void _validate() {
    _log("validate");
    if (widget.validator != null) {
      _errorText.value = widget.validator!(_value);
    }
  }

  @mustCallSuper
  bool validate() {
    _isPassed = true;
    _validate();
    rebuild();
    return !hasError;
  }

  void reset() {
    _log("reset: $value => $_stateInitialValue");

    _isPassed = false;
    _focusedBefore = false;
    setValue(_stateInitialValue);
  }

  void save() {
    _log("save: $_stateInitialValue => $value");
    _stateInitialValue = value;
    widget.onSaved?.call(value);
  }

  void _log(String functionName) {
    if (kLoggingEnabled) {
      final fieldType = "$widget.runtimeType".split("FormField").first;
      final fieldName =
          widget.decoration?.label ?? widget.decoration?.hint ?? "";

      FormLog.d(fieldType, functionName, 1, fieldName: fieldName);
    }
  }
}
