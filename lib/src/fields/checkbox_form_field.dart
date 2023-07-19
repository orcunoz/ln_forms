import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';

class CheckboxFormField extends InputFormField<bool?> {
  final bool tristate;
  final Widget? suffixIcon;

  CheckboxFormField({
    super.key,
    String? labelText,
    Widget? label,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.readOnly,
    super.enabled,
    super.focusNode,
    super.validator,
    super.style,
    this.tristate = false,
    this.suffixIcon,
  })  : assert(label != null || labelText != null,
            "label or labelText must be passed"),
        super(
          clearable: false,
          restoreable: false,
          useFocusNode: false,
          builder: (InputFormFieldState<bool?> field) {
            final CheckboxFormFieldState state =
                field as CheckboxFormFieldState;

            final EdgeInsets padding =
                state.effectiveDecoration.contentPadding?.at(field.context) ??
                    EdgeInsets.zero;
            final Widget labelWidget = label ?? Text(labelText!);
            Widget child;

            if (readOnly) {
              child = Icon(
                state.value == true ? Icons.check_rounded : Icons.clear_rounded,
                color: state.baseTextStyle.color,
                size: 22,
              );
            } else {
              child = Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: state.isActive ? state.didChange : null,
                value: state.value,
                focusNode: state.effectiveFocusNode,
                tristate: tristate,
                isError:
                    state.effectiveDecoration.errorText?.isNotEmpty == true,
              );
            }

            child = SpacedRow(
              spacing: readOnly ? 9 : 4,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                Flexible(child: labelWidget),
              ],
            );

            return Transform.translate(
              offset: Offset(-padding.left, readOnly ? -4 : 0),
              child: child,
            );
          },
        );

  @override
  CheckboxFormFieldState createState() => CheckboxFormFieldState();
}

class CheckboxFormFieldState extends InputFormFieldState<bool?> {
  @override
  CheckboxFormField get widget => super.widget as CheckboxFormField;

  @override
  void handleTap() {
    super.handleTap();

    final opts = [if (widget.tristate) null, false, true];
    final currentIndex = opts.indexOf(value);
    final nextIndex = (currentIndex + 1) % opts.length;

    didChange(opts[nextIndex]);
  }

  @override
  InputDecoration get effectiveDecoration => super.effectiveDecoration.copyWith(
        border: super.effectiveDecoration.readOnlyBorder,
        enabledBorder: super.effectiveDecoration.readOnlyBorder,
        focusedBorder: super.effectiveDecoration.readOnlyBorder,
        disabledBorder: super.effectiveDecoration.readOnlyBorder,
        errorBorder: super.effectiveDecoration.readOnlyBorder,
        focusedErrorBorder: super.effectiveDecoration.readOnlyBorder,
        hoverColor: super.effectiveDecoration.fillColor,
        fillColor: Colors.transparent,
        suffixIcon: widget.readOnly ? null : widget.suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
        constraints: const BoxConstraints(minHeight: 0),
      );
}
