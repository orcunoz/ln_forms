import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/utilities/logger.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:ln_core/ln_core.dart';

import 'widgets/empty_readonly_placeholder.dart';

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
    super.validator,
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
          enabled: enabled ?? /*decoration?.enabled ??*/ true,
          builder: (FormFieldState<T> field) {
            final InputFormFieldState<T> state =
                field as InputFormFieldState<T>;

            Widget child = state.isEmpty && readOnly
                ? EmptyReadOnlyPlaceholder(
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
              InputDecoration decoration = state.effectiveDecoration;

              child = AnimatedBuilder(
                animation: state.effectiveFocusNode,
                builder: (BuildContext context, Widget? child) {
                  return InputDecorator(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: decoration,
                    baseStyle: state.baseTextStyle,
                    isHovering: state.isHovering,
                    isFocused: state.isFocused,
                    isEmpty: state.isEmpty,
                    child: child,
                  );
                },
                child: child,
              );

              /*bool notSaved = state._stateInitialValue != state.value;
              child = Container(
                padding: EdgeInsets.only(right: notSaved ? 6 : 0),
                decoration: BoxDecoration(
                  color: notSaved
                      ? Color.fromARGB(255, 255, 199, 116)
                      : Colors.transparent,
                  borderRadius: decoration.borderRadius,
                ),
                child: child,
              );*/
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

            return GestureDetector(
              onTap: () => state.isActive ? state.handleTap() : null,
              child: child,
            );
          },
        );

  @override
  InputFormFieldState<T> createState() => InputFormFieldState<T>();
}

class InputFormFieldState<T> extends FormFieldState<T> {
  // ignore: unused_field
  int _generation = 0;

  T? _stateInitialValue;
  bool _focusedBefore = false;
  bool _isPassed = false;
  bool get isPassed => _isPassed;

  bool _isHovering = false;
  bool get isHovering => _isHovering;

  bool get isActive => !widget.readOnly && widget.enabled;

  bool get isFocused => isActive && effectiveFocusNode.hasFocus;

  bool get isEmpty => Validator.isEmptyValue(value);

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
      widget.restoreable ?? !Validator.isEmptyValue(widget.initialValue);

  bool get effectiveClearable =>
      widget.clearable ?? Validator.isEmptyValue(widget.initialValue);

  Widget? get editingActionButton {
    if (isActive && UniversalPlatform.isDesktopOrWeb ? isHovering : isFocused) {
      if (effectiveRestorable && value != _stateInitialValue) {
        return IconButton(
          icon: const Icon(Icons.settings_backup_restore_rounded),
          focusNode: editingActionButtonFocusNode,
          onPressed: () => didChange(_stateInitialValue),
          //tooltip: S.current.restore,
        );
      } else if (effectiveClearable && !isEmpty) {
        return IconButton(
          icon: const Icon(Icons.clear_rounded),
          focusNode: editingActionButtonFocusNode,
          onPressed: () => didChange(null),
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

    if (widget.readOnly) {
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
    log("initState", StackTrace.current);
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
    log("didUpdateWidget", StackTrace.current);
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
    log("didChangeDependencies", StackTrace.current);
    super.didChangeDependencies();

    if (widget.initialValue != _stateInitialValue) {
      log(
          "didChangeDependencies -> initialValueChanged: "
          "${widget.initialValue?.toString().limitLength(30)}->"
          "${_stateInitialValue?.toString().limitLength(30)}",
          StackTrace.current);
    }
  }

  @override
  void dispose() {
    log("dispose", StackTrace.current);
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
      log("didChange: $value", StackTrace.current);
      super.didChange(value);
      if (widget.onChanged != null) widget.onChanged!(value);
    }
  }

  @mustCallSuper
  void handleFocusChanged(bool hasFocus) {
    log("handler -> focusChange: $hasFocus", StackTrace.current);

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
    log("handler -> onKeyEvent(${event.runtimeType}): ${event.logicalKey.keyLabel}",
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
    log("handler -> tap", StackTrace.current);
  }

  @mustCallSuper
  void handleTapOutside() {
    assert(isActive && effectiveFocusNode.hasFocus);
    log("handler -> tapOutside", StackTrace.current);
    if (widget.unfocusWhenTapOutside) {
      effectiveFocusNode.unfocus();
    }
  }

  @mustCallSuper
  void handleHover(bool hovering) {
    assert(isActive || (_isHovering && !hovering));
    if (hovering == _isHovering) return;
    log("handler -> hover: $hovering", StackTrace.current);

    _isHovering = hovering;
    rebuild();
  }

  @mustCallSuper
  @override
  bool validate() {
    log("validate", StackTrace.current);
    _isPassed = true;
    return super.validate();
  }

  @override
  void reset() {
    log("reset: $value => $_stateInitialValue", StackTrace.current);
    _isPassed = false;
    _focusedBefore = false;
    super.reset();
    if (_stateInitialValue != value) didChange(_stateInitialValue);
    if (widget.onChanged != null) widget.onChanged!(_stateInitialValue);
  }

  @override
  void save() {
    log("save: $_stateInitialValue => $value", StackTrace.current);
    _stateInitialValue = value;
    super.save();
  }

  void log(String functionName, StackTrace stackTrace) {
    if (kLoggingEnabled) {
      final fieldType = widget.runtimeType.toString().split("FormField").first;
      final fieldName =
          widget.decoration?.label ?? widget.decoration?.hint ?? "";

      FormLog.d(fieldType, functionName, 1, fieldName: fieldName);
    }
  }

  @override
  Widget build(BuildContext context) {
    _effectiveDecoration = null;
    return super.build(context);
  }
}
