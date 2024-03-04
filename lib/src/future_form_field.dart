part of 'form.dart';

typedef FutureFieldBuilder<T, CT> = Widget? Function(
    LnFutureFieldState<T, CT>, ComputedEditableProps);

typedef SimpleFutureFieldBuilder<T> = Widget? Function(
    LnSimpleFutureFieldState<T>, ComputedEditableProps);

abstract class LnSimpleFutureField<T> extends LnFutureField<T, T> {
  LnSimpleFutureField({
    required super.key,
    required super.value,
    required super.onChanged,
    required super.onSaved,
    required super.focusNode,
    required super.useFocusNode,
    super.autofocus = false,
    super.mouseCursor = MouseCursor.defer,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    required super.validator,
    required super.style,
    required super.decoration,
    required SimpleFutureFieldBuilder<T> builder,
    super.restorationId,
    super.onFocusChanged,
    super.onKeyEvent,
    super.onTap,
    super.onPointerEnter,
    super.onPointerExit,
    required Future<T?> Function(LnSimpleFutureFieldState<T>) onTrigger,
    required FieldController<T>? super.controller,
    required this.emptyValue,
  }) : super(
          onTrigger: (state) => onTrigger(state as LnSimpleFutureFieldState<T>),
          builder: (field, computedProps) =>
              builder(field as LnSimpleFutureFieldState<T>, computedProps),
        );

  final T? emptyValue;

  @override
  LnSimpleFutureFieldState<T> createState() {
    return LnSimpleFutureFieldState<T>();
  }
}

class LnSimpleFutureFieldState<T> extends LnFutureFieldState<T, T> {
  @override
  LnSimpleFutureField<T> get widget => super.widget as LnSimpleFutureField<T>;

  @override
  FieldController<T> createController(T value) {
    return FieldController<T>(value, emptyValue: widget.emptyValue);
  }
}

abstract class LnFutureField<T, CT> extends LnFormField<T, CT> {
  LnFutureField({
    required super.key,
    required super.value,
    required super.onChanged,
    required super.onSaved,
    required super.focusNode,
    required super.useFocusNode,
    super.autofocus = false,
    super.mouseCursor,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    required super.validator,
    required super.style,
    required super.decoration,
    required FutureFieldBuilder<T, CT> builder,
    super.restorationId,
    super.onFocusChanged,
    super.onKeyEvent,
    super.onTap,
    super.onPointerEnter,
    super.onPointerExit,
    required this.onTrigger,
    required super.controller,
  }) : super(
          builder: (field, computedProps) =>
              builder(field as LnFutureFieldState<T, CT>, computedProps),
        );

  final Future<T?> Function(LnFutureFieldState<T, CT>) onTrigger;

  @override
  LnFutureFieldState<T, CT> createState();
}

abstract class LnFutureFieldState<T, CT> extends LnFormFieldState<T, CT> {
  @override
  LnFutureField<T, CT> get widget => super.widget as LnFutureField<T, CT>;

  Future<T?>? future;

  @override
  bool get focused => future != null || super.focused;

  @override
  String? get errorText => future != null ? null : super.errorText;

  @override
  MouseCursor get mouseCursor => MaterialStateProperty.resolveAs<MouseCursor>(
        MaterialStateMouseCursor.clickable,
        <MaterialState>{
          if (computedState.active) MaterialState.disabled,
        },
      );

  @override
  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        future == null) {
      _invoke();
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event);
  }

  @override
  void onTap() {
    super.onTap();

    _invoke();
  }

  Future<T?> _invoke() async {
    if (future != null) return Future.value(null);
    future = widget.onTrigger(this);
    rebuild();

    final result = await future;

    future = null;
    if (result != null) {
      controller.fieldValue = result;
    }
    Future.delayed(Duration(milliseconds: 50), requestFocus);

    return result;
  }
}
