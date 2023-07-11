import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_forms/src/utils/logger.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:ln_core/ln_core.dart';

import 'ln_forms_base.dart';

class InputFormField<T> extends FormField<T> {
  final TextStyle? style;
  final LnDecoration? decoration;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool autofocus;
  final bool? clearable;
  final bool? restoreable;

  final bool unfocusWhenTapOutside;

  final void Function(T?)? onChanged;

  InputFormField({
    super.key,
    super.initialValue,
    this.onChanged,
    required super.onSaved,
    this.focusNode,
    required bool useFocusNode,
    this.autofocus = false,
    bool? enabled,
    this.readOnly = false,
    String? Function(T?)? validate,
    this.clearable,
    this.restoreable,
    this.style,
    this.decoration = const LnDecoration(),
    required Widget? Function(InputFormFieldState<T> state) builder,
    bool absorbInsideTapEvents = false,
    bool handleTapOutsideWhenFocused = false,
    this.unfocusWhenTapOutside = false,
  }) : super(
          autovalidateMode: AutovalidateMode.always,
          validator: (val) => validate?.call(val),
          enabled: enabled ?? /*decoration?.enabled ??*/ true,
          builder: (FormFieldState<T> field) {
            final InputFormFieldState<T> state =
                field as InputFormFieldState<T>;

            Widget child = state.isEmpty && readOnly
                ? EmptyReadOnlyStatePlaceholder(
                    color: Theme.of(state.context).hintColor,
                  )
                : builder(state) ?? const SizedBox();

            child = DefaultTextStyle(
              style: state.baseTextStyle,
              child: child,
            );

            if (absorbInsideTapEvents) {
              child = AbsorbPointer(
                child: child,
              );
            }

            if (decoration != null) {
              child = AnimatedBuilder(
                animation: state.effectiveFocusNode,
                builder: (BuildContext context, Widget? child) {
                  return InputDecorator(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: state.effectiveDecoration,
                    baseStyle: state.baseTextStyle,
                    isHovering: state.isHovering,
                    isFocused: state.isFocused,
                    isEmpty: state.isEmpty,
                    child: child,
                  );
                },
                child: child,
              );
            }

            child = Opacity(
              opacity: field.widget.enabled ? 1 : 0.5,
              child: child,
            );

            if (handleTapOutsideWhenFocused) {
              child = TapRegion(
                enabled: state.effectiveFocusNode.hasFocus,
                onTapOutside: (_) => state.handleTapOutside(),
                behavior: HitTestBehavior.opaque,
                debugLabel: 'InputFormField',
                child: child,
              );
            }

            child = MouseRegion(
              cursor: state.effectiveMouseCursor,
              onEnter: (_) => state.isActive ? state.handleHover(true) : null,
              onExit: (_) => state.isActive || state.isHovering
                  ? state.handleHover(false)
                  : null,
              child: child,
            );

            child = Focus(
              canRequestFocus: state.isActive,
              skipTraversal: useFocusNode ? null : true,
              focusNode: useFocusNode ? state.effectiveFocusNode : null,
              //parentNode: useFocusNode ? null : state.effectiveFocusNode,
              onFocusChange: state.handleFocusChanged,
              onKeyEvent: (node, event) => state.effectiveFocusNode.hasFocus
                  ? state.handleKeyEvent(event)
                  : KeyEventResult.ignored,
              child: child,
            );

/*            child = Stack(
              children: [
                child,
                Align(
                  alignment: Alignment.topRight,
                  child: Tooltip(
                      message: "Changed and not saved",
                      child: Container(
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [ElevationBoxShadow(0)],
                        ),
                      )),
                ),
              ],
            );*/

            return GestureDetector(
              onTap: () => state.isActive ? state.handleTap() : null,
              child: child,
            );
          },
        );

  @override
  InputFormFieldState<T> createState() => InputFormFieldState<T>();
}

bool _isEmpty(dynamic value) =>
    value == null ||
    (value is String && value.isEmpty) ||
    (value is Iterable && value.isEmpty);

class InputFormFieldState<T> extends FormFieldState<T> {
  int _generation = 0;

  T? _stateInitialValue;
  bool _focusedBefore = false;
  bool _isPassed = false;
  bool get isPassed => _isPassed;

  bool _isHovering = false;
  bool get isHovering => _isHovering;

  bool get isActive => !widget.readOnly && widget.enabled;

  bool get isFocused => isActive && effectiveFocusNode.hasFocus;

  bool get isEmpty => _isEmpty(value);

  @override
  bool get hasError => errorText?.isNotEmpty == true;

  FocusNode? _internalNode;
  FocusNode get effectiveFocusNode => widget.focusNode ?? _internalNode!;

  @override
  InputFormField<T> get widget => super.widget as InputFormField<T>;

  TextStyle get baseTextStyle =>
      Theme.of(context).defaultFormFieldStyle.merge(widget.style);

  FocusNode? _editingActionButtonFocusNode;
  FocusNode get editingActionButtonFocusNode =>
      _editingActionButtonFocusNode ??=
          FocusNode(skipTraversal: true, canRequestFocus: true);

  bool get effectiveRestorable =>
      widget.restoreable ?? !_isEmpty(widget.initialValue);

  bool get effectiveClearable =>
      widget.clearable ?? _isEmpty(widget.initialValue);

  Widget? get editingActionButton {
    if (isActive && UniversalPlatform.isDesktopOrWeb ? isHovering : isFocused) {
      if (effectiveRestorable && value != _stateInitialValue) {
        return IconButton(
          icon: const Icon(Icons.settings_backup_restore_rounded),
          focusNode: editingActionButtonFocusNode,
          onPressed: () => didChange(_stateInitialValue),
          //tooltip: S.of(context).restore,
        );
      } else if (effectiveClearable && !isEmpty) {
        return IconButton(
          icon: const Icon(Icons.clear_rounded),
          focusNode: editingActionButtonFocusNode,
          onPressed: () => didChange(null),
          //tooltip: S.of(context).clear,
        );
      }
    }

    return null;
  }

  MouseCursor get effectiveMouseCursor => MouseCursor.defer;

  LnDecoration get baseDecoration => const LnDecoration();

  InputDecoration? _effectiveDecoration;
  InputDecoration get effectiveDecoration {
    assert(_effectiveDecoration != null);
    return _effectiveDecoration!;
  }

  InputDecoration _prepareDecorationForBuild() {
    LnDecoration decorationBase = (widget.decoration ?? const LnDecoration())
        .applyDefaults(baseDecoration);

    if (widget.readOnly) {
      decorationBase = decorationBase.apply(
        hint: const Wrapped.value(null),
        counter: const Wrapped.value(null),
        suffixIcon: const Wrapped.value(null),
        error: const Wrapped.value(null),
        helper: const Wrapped.value(null),
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

    if (widget.readOnly) {
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

  void _createInternalFocusNode() {
    assert(_internalNode == null);
    _internalNode = FocusNode();
  }

  void rebuild() {
    if (!mounted) return;
    setState(() {
      ++_generation;
    });
  }

  @override
  void initState() {
    debugLog("initState", StackTrace.current);
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
  void didUpdateWidget(InputFormField<T> oldWidget) {
    debugLog("didUpdateWidget", StackTrace.current);
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
    debugLog("didChangeDependencies", StackTrace.current);
    super.didChangeDependencies();

    if (widget.initialValue != _stateInitialValue) {
      debugLog(
          "didChangeDependencies: initialValueChanged: "
          "${widget.initialValue?.toString().limitLength(30)}->"
          "${_stateInitialValue?.toString().limitLength(30)}",
          StackTrace.current);
    }
  }

  @override
  void dispose() {
    debugLog("dispose", StackTrace.current);
    _internalNode?.dispose();
    _editingActionButtonFocusNode?.dispose();
    super.dispose();
  }

  /*void _focusChangeListener() {
    handleFocusChanged(effectiveFocusNode.hasFocus);
  }*/

  @override
  void didChange(T? value) {
    if (this.value != value) {
      debugLog("didChange: $value", StackTrace.current);
      if (widget.onChanged != null) widget.onChanged!(value);
      super.didChange(value);
    }
  }

  @mustCallSuper
  void handleFocusChanged(bool hasFocus) {
    debugLog("handler -> focusChange: $hasFocus", StackTrace.current);

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
    debugLog(
        "handler -> onKeyEvent(${event.runtimeType}): ${event.logicalKey.keyLabel}",
        StackTrace.current);

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      effectiveFocusNode.unfocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @mustCallSuper
  void handleTap() {
    assert(isActive);
    debugLog("handler -> tap", StackTrace.current);
  }

  @mustCallSuper
  void handleTapOutside() {
    assert(isActive && effectiveFocusNode.hasFocus);
    debugLog("handler -> tapOutside", StackTrace.current);
    if (widget.unfocusWhenTapOutside) {
      effectiveFocusNode.unfocus();
    }
  }

  @mustCallSuper
  void handleHover(bool hovering) {
    assert(isActive || (_isHovering && !hovering));
    if (hovering == _isHovering) return;
    debugLog("handler -> hover: $hovering", StackTrace.current);

    _isHovering = hovering;
    rebuild();
  }

  @mustCallSuper
  @override
  bool validate() {
    debugLog("validate", StackTrace.current);
    _isPassed = true;
    return super.validate();
  }

  @override
  void reset() {
    debugLog("reset: $value => $_stateInitialValue", StackTrace.current);
    _isPassed = false;
    _focusedBefore = false;
    super.reset();
    if (_stateInitialValue != value) didChange(_stateInitialValue);
    if (widget.onChanged != null) widget.onChanged!(_stateInitialValue);
  }

  @override
  void save() {
    debugLog("save: $_stateInitialValue => $value", StackTrace.current);
    _stateInitialValue = value;
    super.save();
  }

  @override
  Widget build(BuildContext context) {
    //effectiveFocusNode.canRequestFocus = isActive;
    _effectiveDecoration = _prepareDecorationForBuild();
    return super.build(context);
  }

  void debugLog(String functionName, StackTrace stackTrace) {
    Log.form(
        widget.runtimeType.toString().split("FormField").first, functionName, 1,
        fieldName: widget.decoration?.label ?? widget.decoration?.hint ?? "");
  }
}

class EmptyReadOnlyStatePlaceholder extends Align {
  EmptyReadOnlyStatePlaceholder({
    super.key,
    Color? color,
  }) : super(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 24, height: 1.5),
            child: Divider(
              height: 1.5,
              thickness: 1.5,
              color: color,
            ),
          ),
        );
}

mixin FutureFormField<T> on InputFormFieldState<T> {
  Future<T?>? future;

  @override
  bool get isFocused => super.isFocused || future != null;

  @override
  MouseCursor get effectiveMouseCursor =>
      MaterialStateProperty.resolveAs<MouseCursor>(
        MaterialStateMouseCursor.clickable,
        <MaterialState>{
          if (widget.readOnly) MaterialState.disabled,
          if (!widget.enabled) MaterialState.disabled,
        },
      );

  @override
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        future == null) {
      invoke();
      return KeyEventResult.handled;
    }
    return super.handleKeyEvent(event);
  }

  @override
  void handleTap() {
    super.handleTap();

    if (!effectiveFocusNode.hasFocus) {
      effectiveFocusNode.requestFocus();
    }

    invoke();
  }

  Future<T?> invoke() async {
    future = toFuture();
    final result = await future;

    //effectiveFocusNode.requestFocus();
    rebuild();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      future = null;
      if (result != null) {
        didChange(result);
      }
    });

    return result;
  }

  Future<T?> toFuture() {
    throw Exception("You have to override this method!");
  }
}
