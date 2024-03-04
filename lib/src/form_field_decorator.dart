import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/src/utilities/extensions.dart';

import 'widgets/empty_readonly_field.dart';

class LnFormFieldDecorator extends Builder {
  LnFormFieldDecorator({
    required bool enabled,
    required bool readOnly,
    required bool hovered,
    required bool focused,
    required bool empty,
    required final InputDecoration? decoration,
    required TextStyle baseTextStyle,
    required Widget? child,
  }) : super(builder: (context) {
          Widget result = Visibility(
            visible: !(empty && readOnly),
            replacement: EmptyReadOnlyField(),
            child: child ?? SizedBox.shrink(),
          );

          result = Opacity(
            opacity: enabled ? 1 : 0.5,
            child: DefaultTextStyle(
              style: baseTextStyle,
              child: result,
            ),
          );

          if (decoration == null) {
            return result;
          }

          final InputDecoration effectiveDecoration;

          if (readOnly) {
            final readOnlyBorder = decoration.readOnlyBorder;
            effectiveDecoration = decoration
                .copyWith(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  //contentPadding: dec.contentPadding?.removeHorizontal,
                  filled: false,
                  border: readOnlyBorder,
                  errorBorder: readOnlyBorder,
                  enabledBorder: readOnlyBorder,
                  focusedBorder: readOnlyBorder,
                  disabledBorder: readOnlyBorder,
                  focusedErrorBorder: readOnlyBorder,
                )
                .apply(
                  hint: Wrapped(null),
                  counter: Wrapped(null),
                  suffixIcon: Wrapped(null),
                  error: Wrapped(null),
                  helper: Wrapped(null),
                );
          } else {
            Color? fillColor;

            if (decoration.errorText != null) {
              final errorColor = decoration.errorBorder?.borderSide.color ??
                  Theme.of(context).colorScheme.error;
              fillColor = errorColor.withOpacity(.1);
            } else if (focused) {
              fillColor = decoration.focusColor ?? Theme.of(context).focusColor;
              if (hovered) {
                final hoverColor =
                    decoration.hoverColor ?? Theme.of(context).hoverColor;
                fillColor = Color.alphaBlend(hoverColor, fillColor);
              }
            }

            if (!enabled) {
              fillColor =
                  (fillColor ?? decoration.fillColor)?.withOpacityFactor(.5);
            }

            effectiveDecoration = fillColor != null
                ? decoration.copyWith(fillColor: fillColor)
                : decoration;
          }

          result = InputDecorator(
            textAlignVertical: TextAlignVertical.center,
            baseStyle: baseTextStyle,
            isFocused: focused,
            isHovering: hovered,
            isEmpty: empty,
            decoration: effectiveDecoration.copyWith(
                suffixIcon: const Icon(Icons.clear_rounded)),
            child: result,
          );

          return result;
        });
}
