part of 'form.dart';

typedef ValueValidator<T> = String? Function(T);

typedef FieldOnTap = void Function();
typedef FieldOnTapOutside = void Function();
typedef FieldOnFocusChanged = void Function(bool);
typedef FieldOnKeyEvent = KeyEventResult Function(KeyEvent);
typedef FieldOnPointerEnter = void Function(PointerEnterEvent);
typedef FieldOnPointerExit = void Function(PointerExitEvent);

abstract class LnFormField<T, CT> extends EditablePropsWidget {
  LnFormField({
    required super.key,
    required this.value,
    required this.onChanged,
    required this.onSaved,
    required this.focusNode,
    required this.useFocusNode,
    this.autofocus = false,
    this.mouseCursor,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    required this.validator,
    required this.style,
    required this.decoration,
    required this.builder,
    this.restorationId,
    this.onFocusChanged,
    this.onKeyEvent,
    this.onTap,
    this.onPointerEnter,
    this.onPointerExit,
    this.disableGestures = false,
    required this.controller,
  })  : assert(value == null || controller == null),
        assert(
            controller != null || value != null || null is T,
            "label: ${decoration?.label}, "
            "controller: $controller, "
            "value: $value, "
            "isNullable: ${null is T}");

  final T? value;
  final TextStyle? style;
  final LnDecoration? decoration;
  final FocusNode? focusNode;
  final bool useFocusNode;
  final bool autofocus;
  final bool disableGestures;

  final MouseCursor? mouseCursor;

  final ValueValidator<T>? validator;
  final Widget? Function(LnFormFieldState<T, CT>, ComputedEditableProps)
      builder;

  final String? restorationId;

  final ValueChanged<T>? onSaved;
  final ValueChanged<T>? onChanged;

  final FieldOnTap? onTap;
  final FieldOnFocusChanged? onFocusChanged;
  final FieldOnKeyEvent? onKeyEvent;
  final FieldOnPointerEnter? onPointerEnter;
  final FieldOnPointerExit? onPointerExit;

  final BaseFieldController<CT, T>? controller;

  @override
  LnFormFieldState<T, CT> createState();
}

abstract class LnSimpleField<T> extends LnFormField<T, T> {
  LnSimpleField({
    required super.key,
    required super.value,
    required super.onChanged,
    required super.onSaved,
    required super.focusNode,
    required super.useFocusNode,
    super.autofocus,
    super.mouseCursor,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    required super.validator,
    required super.style,
    required super.decoration,
    required super.builder,
    super.restorationId,
    super.onFocusChanged,
    super.onKeyEvent,
    super.onTap,
    super.onPointerEnter,
    super.onPointerExit,
    required super.controller,
    required this.emptyValue,
    super.disableGestures,
  });

  final T emptyValue;

  @override
  LnSimpleFieldState<T> createState() {
    return LnSimpleFieldState<T>();
  }
}

mixin _FormFieldControllerMixin<T, CT> on LnState<LnFormField<T, CT>>
    implements FieldLoggerMixin {
  BaseFieldController<CT, T>? _localController;
  BaseFieldController<CT, T> get controller =>
      widget.controller ?? _localController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _createInternalController(widget.value as T);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
  }

  //Restoration
  /*@override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_localController != null) {
      _registerController();
    }
    registerForRestoration(_errorText, 'error_text');
  }*/

  @override
  void didUpdateWidget(covariant LnFormField<T, CT> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        //unregisterFromRestoration(_localController!);
        _localController!.dispose();
        _localController = null;
      } else {
        oldWidget.controller!.removeListener(_handleControllerChanged);
      }

      if (widget.controller == null) {
        _createInternalController(oldWidget.value as T);
      } else {
        widget.controller!.addListener(_handleControllerChanged);
      }
    } else if (oldWidget.value != widget.value && widget.controller == null) {
      endOfFrame(() {
        _localController!.value = _localController!.valueOf(widget.value as T);
      });
    }
  }

  BaseFieldController<CT, T> createController(T value);

  //Restoration
  /*void _registerController() {
    assert(_localController != null);
    registerForRestoration(_localController!, 'controller');
  }*/

  void _createInternalController(T value) {
    assert(_localController == null);
    _localController = createController(value)
      ..addListener(_handleControllerChanged);

    //Restoration
    /*if (!restorePending) {
      _registerController();
    }*/
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.controller != null) {
      widget.controller!.removeListener(_handleControllerChanged);
    } else {
      _localController!.dispose();
    }
  }

  void _handleControllerChanged() {
    final value = controller.fieldValueOf(controller.value);
    onValueChanged(value);
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }

  void onValueChanged(T value) {}
}

mixin _FieldValidator<T, CT> on RestorationMixin<LnFormField<T, CT>>
    implements FieldLoggerMixin {
  ValueValidator<T>? get validator;
  T get value;

  final RestorableStringN _errorText = RestorableStringN(null);
  Listenable get errorListenable => _errorText;
  String? get errorText => _errorText.value;
  bool get hasError => errorText != null;

  bool _isPassed = false;
  void setPassed(bool val) {
    if (val == _isPassed) return;

    _isPassed = val;
  }

  void _validateIfPassed() {
    String? error;
    if (_isPassed && validator != null) {
      error = validator!(value);
    }

    _errorText.value = error;
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_errorText, 'error_text');
  }

  bool validate() {
    log("events.validate(isPassed: $_isPassed)");
    if (!_isPassed) {
      setPassed(true);
    }

    _validateIfPassed();

    return !hasError;
  }
}

mixin _FieldFocusNode<T, CT> on LnState<LnFormField<T, CT>>
    implements FieldLoggerMixin {
  FocusNode? _internalNode;
  FocusNode get effectiveFocusNode => widget.focusNode ?? _internalNode!;
  Listenable get focusListenable => effectiveFocusNode;
  bool _focused = false;
  bool get focused => _focused;

  void requestFocus() {
    if (!_focused) {
      log("actions.requestFocus(focusedBefore: $_focused)");
      effectiveFocusNode.requestFocus();
    }
  }

  void unfocus() {
    if (_focused) {
      log("actions.unfocus(isFocused: $_focused)");
      effectiveFocusNode.unfocus();
    }
  }

  void _syncNode(FocusNode? node) {
    node
      ?..addListener(_handleFocusChanged)
      ..onKeyEvent = _handleKeyEvent;

    if (node != null && _focused != node.hasFocus) {
      _focused = node.hasFocus;
      node.requestFocus();
    }
  }

  void _removeNodeListeners(FocusNode? node) {
    node?.removeListener(_handleFocusChanged);
    if (node?.onKeyEvent == _handleKeyEvent) {
      node?.onKeyEvent = null;
    }
  }

  void _createInternalFocusNode() {
    assert(_internalNode == null);
    assert(widget.focusNode == null);
    _internalNode = FocusNode();
    _syncNode(_internalNode);
  }

  @override
  void initState() {
    super.initState();

    if (widget.focusNode == null) {
      _createInternalFocusNode();
    } else {
      _syncNode(widget.focusNode);
    }
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalNode!.dispose();
        _internalNode = null;
      } else {
        _removeNodeListeners(oldWidget.focusNode);
      }

      if (widget.focusNode == null) {
        _createInternalFocusNode();
      } else {
        _syncNode(widget.focusNode);
      }
    }
  }

  _handleFocusChanged() {
    final nodeFocused = effectiveFocusNode.hasFocus;
    if (nodeFocused != _focused) {
      _focused = nodeFocused;
      onFocusChanged(nodeFocused);
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged!(nodeFocused);
      }
    }
  }

  void onFocusChanged(bool focused) {}

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_focused) {
      return KeyEventResult.ignored;
    }
    log("handlers.onKeyEvent(${event.runtimeType}: "
        "${event.logicalKey.keyLabel})");

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      unfocus();
      return KeyEventResult.handled;
    }

    if (widget.onKeyEvent != null) {
      widget.onKeyEvent!(event);
    }

    return onKeyEvent(event);
  }

  @mustCallSuper
  KeyEventResult onKeyEvent(KeyEvent event) {
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.focusNode == null) {
      _internalNode!.dispose();
    } else {
      _removeNodeListeners(widget.focusNode);
    }
  }
}

abstract class LnFormFieldState<T, CT>
    extends ScopedEditablePropsWidgetState<LnFormField<T, CT>>
    with
        RestorationMixin<LnFormField<T, CT>>,
        FieldLoggerMixin,
        _FieldValidator<T, CT>,
        _FormFieldControllerMixin<T, CT>,
        _FieldFocusNode<T, CT> {
  @override
  T get value => controller.fieldValue;

  bool get isEmpty => controller.isEmpty;

  @override
  String get loggerFieldName =>
      widget.decoration?.label ?? widget.decoration?.hint ?? "";

  @override
  ValueValidator<T>? get validator => widget.validator;

  late final FocusNode _editingActionButtonFocusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  LnFormController? _subscribedForm;

  TextStyle get baseStyle => theme.formFieldStyle.merge(widget.style);

  final _hoverNotifier = ValueNotifier<bool>(false);
  Listenable get hoverListenable => _hoverNotifier;
  bool get hovered => _hoverNotifier.value;

  MouseCursor? get mouseCursor => widget.mouseCursor;

  InputDecoration? _computedDecoration;
  InputDecoration? get computedDecoration => _computedDecoration;

  @override
  EditablePropsMixin? get editableScopeProps => _subscribedForm?.scopedState;

  @override
  void onComputedEditableStateChanged() {
    rebuild();
  }

  Widget? buildActionButton(BuildContext context, FocusNode focusNode) {
    final show = computedState.active &&
        (UniversalPlatform.isDesktop || UniversalPlatform.isWeb
            ? hovered
            : focused);

    if (show) {
      if (computedState.restoreable && controller.unsaved) {
        return InkWell(
          focusNode: focusNode,
          onTap: controller.restore,
          child: const Icon(Icons.settings_backup_restore_rounded),
          //tooltip: S.current.restore,
        );
      } else if (computedState.clearable && !controller.isEmpty) {
        return InkWell(
          focusNode: focusNode,
          onTap: controller.clear,
          child: const Icon(Icons.clear_rounded),
          //tooltip: S.current.clear,
        );
      }
    }

    return null;
  }

  @mustCallSuper
  void onTap() {
    log("handlers.onTap");

    if (!_focused) {
      requestFocus();
    }
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @mustCallSuper
  @override
  void onFocusChanged(bool focused) {
    log("handlers.onFocusChanged($focused)");
    if (!focused) {
      setPassed(true);
    }
    super.onFocusChanged(focused);
  }

  @override
  void _handleControllerChanged() {
    super._handleControllerChanged();
    _subscribedForm?.handleFieldValueChanged();
  }

  FutureOr<void> ensureVisible() {
    final scrollPosition = Scrollable.maybeOf(context)?.position;
    if (scrollPosition != null) {
      context.findRenderObject()?.ensureVisible(scrollPosition);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final form = LnForm.maybeOf(context);
    if (form != _subscribedForm) {
      _subscribedForm?._unregister(this);
      _subscribedForm = form?.._register(this);
      notifyEditableScopePropsChanged();
    }
  }

  @override
  void dispose() {
    _subscribedForm?._unregister(this);
    _editingActionButtonFocusNode.dispose();
    super.dispose();
  }

  void _computeDecoration() {
    final actionButton = buildActionButton(
      context,
      _editingActionButtonFocusNode,
    );

    InputDecoration? decoration =
        widget.decoration?.build().applyDefaults(theme.inputDecorationTheme);

    if (actionButton != null || errorText != null) {
      decoration = decoration?.copyWith(
        suffixIcon: const Icon(Icons.clear_rounded),
        errorText: errorText,
      );
    }

    _computedDecoration =
        decoration?.copyWith(suffixIcon: const Icon(Icons.clear_rounded));
  }

  @override
  void logEditableProps() {
    log("EditableProps ----------------------------------");
    super.logEditableProps();
  }

  @override
  Widget build(BuildContext context) {
    Widget result = ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        focusListenable,
        hoverListenable,
        errorListenable,
      ]),
      builder: (context, child) {
        if (!computedState.active && hovered) {
          _hoverNotifier.value = false;
        }
        effectiveFocusNode.canRequestFocus = computedState.active;

        _computeDecoration();

        return LnFormFieldDecorator(
          enabled: computedState.enabled,
          readOnly: computedState.readOnly,
          focused: focused,
          hovered: hovered,
          empty: controller.isEmpty,
          decoration: computedDecoration,
          baseTextStyle: baseStyle,
          child: widget.builder(this, computedState),
        );
      },
    );

    if (!widget.disableGestures) {
      result = LnFormFieldGestures(
        active: computedState.active,
        mouseCursor: mouseCursor,
        focusNode: widget.useFocusNode ? effectiveFocusNode : null,
        autofocus: widget.autofocus,
        onTap: onTap,
        onPointerEnter: (event) {
          _hoverNotifier.value = true;
          if (widget.onPointerEnter != null) {
            widget.onPointerEnter!(event);
          }
        },
        onPointerExit: (event) {
          _hoverNotifier.value = false;
          if (widget.onPointerExit != null) {
            widget.onPointerExit!(event);
          }
        },
        child: result,
      );
    }

    return result;
  }
}

class LnSimpleFieldState<T> extends LnFormFieldState<T, T> {
  @override
  LnSimpleField<T> get widget => super.widget as LnSimpleField<T>;

  @override
  FieldController<T> createController(T value) {
    return FieldController<T>(value, emptyValue: widget.emptyValue);
  }
}
