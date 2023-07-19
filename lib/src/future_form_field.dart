import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'input_form_field.dart';

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
