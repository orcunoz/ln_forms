import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';

class CheckboxField extends LnSimpleField<bool?> {
  CheckboxField({
    super.key,
    String? labelText,
    Widget? label,
    super.value,
    super.controller,
    super.onChanged,
    super.onSaved,
    super.enabled,
    super.readOnly,
    super.autofocus,
    super.focusNode,
    super.validator,
    TextStyle? style,
    this.tristate = false,
    this.suffixIcon,
  })  : assert(label != null || labelText != null,
            "label or labelText must be passed"),
        super(
          useFocusNode: false,
          clearable: false,
          restoreable: false,
          decoration: LnDecoration(),
          style: null,
          builder: (field, computedState) {
            field as _CheckboxFieldState;

            Widget child;

            if (computedState.readOnly) {
              child = Icon(
                field.value == true ? Icons.check_rounded : Icons.clear_rounded,
                color: field.theme.colorScheme.onSurfaceVariant,
                size: 21,
              );
            } else {
              child = AbsorbPointer(
                child: Checkbox(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity(
                    horizontal: VisualDensity.minimumDensity,
                    vertical: VisualDensity.minimumDensity,
                  ),
                  onChanged: computedState.active
                      ? (val) => field.controller.value = val
                      : null,
                  focusColor: Colors.transparent,
                  value: field.value,
                  focusNode: field.effectiveFocusNode,
                  autofocus: autofocus,
                  tristate: tristate,
                  isError: field.hasError,
                ),
              );
            }

            child = SpacedRow(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                child,
                Flexible(child: label ?? Text(labelText!)),
              ],
            );

            return DefaultTextStyle(
              style:
                  style ?? field.theme.formFieldStyle.apply(fontSizeFactor: .9),
              child: Transform.translate(
                offset: Offset(0, computedState.readOnly ? -4 : 0),
                child: child,
              ),
            );
          },
          emptyValue: tristate ? null : false,
        );

  final bool tristate;
  final Widget? suffixIcon;

  @override
  LnSimpleFieldState<bool?> createState() => _CheckboxFieldState();
}

class _CheckboxFieldState extends LnSimpleFieldState<bool?> {
  @override
  CheckboxField get widget => super.widget as CheckboxField;

  @override
  void onTap() {
    super.onTap();

    final opts = [if (widget.tristate) null, false, true];
    final currentIndex = opts.indexOf(value);
    final nextIndex = (currentIndex + 1) % opts.length;

    controller.value = opts[nextIndex];
  }

  @override
  InputDecoration? get computedDecoration {
    final decoration = super.computedDecoration!;
    final defaultBorder =
        decoration.defaultBorder?.frameless ?? InputBorder.none;
    final padding = decoration.contentPadding?.resolve(textDirection);
    return decoration.copyWith(
      border: defaultBorder,
      enabledBorder: defaultBorder,
      focusedBorder: defaultBorder,
      disabledBorder: defaultBorder,
      errorBorder: defaultBorder,
      focusedErrorBorder: defaultBorder,
      suffixIcon: widget.suffixIcon,
      fillColor: Colors.transparent,
      contentPadding: padding?.copyWith(top: 0, bottom: 0),
      //contentPadding: padding?.copyWith(
      //    top: padding.top / 2, bottom: padding.bottom / 2),
    );
  }

  @override
  FieldController<bool?> createController(bool? value) {
    return FieldController<bool?>(value, emptyValue: null);
  }
}
