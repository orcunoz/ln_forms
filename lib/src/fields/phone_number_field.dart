import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/utilities/extensions.dart';
export 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneNumberField extends TextInputField {
  PhoneNumberField({
    super.key,
    String? value,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSaved,
    ValueChanged<String>? onFieldSubmitted,
    super.focusNode,
    super.autofocus,
    super.textInputAction,
    super.validator,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
    int countryCode = 90,
  }) : super(
          decoration: decoration?.copyWith(
            suffixIcon:
                decoration.suffixIcon ?? const Icon(Icons.add_ic_call_rounded),
            prefixText: "+$countryCode",
          ),
          inputFormatters: [_inputFormatter],
          keyboardType: TextInputType.phone,
          value: value == null ? null : _inputFormatter.maskText(value),
          onChanged: _convertHandler(onChanged),
          onSaved: _convertHandler(onSaved),
          onFieldSubmitted: _convertHandler(onFieldSubmitted),
        );

  static ValueChanged<String>? _convertHandler(ValueChanged<String>? handler) {
    if (handler == null) {
      return null;
    } else {
      return (val) => handler(_inputFormatter.unmaskText(val));
    }
  }

  static final _inputFormatter = MaskTextInputFormatter(
    mask: '(###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  TextInputFieldState createState() {
    return PhoneNumberFieldState();
  }
}

class PhoneNumberFieldState extends TextInputFieldState {
  @override
  InputDecoration? get computedDecoration {
    final decoration = super.computedDecoration;
    final prefixText = widget.decoration?.prefixText;

    if (prefixText != null) {
      final padding = EdgeInsets.only(
          left: theme.inputDecorationTheme.contentPadding
                  ?.resolve(textDirection)
                  .left ??
              0);
      return decoration
          ?.apply(
            prefixText: Value(null),
          )
          .copyWith(
            prefixIcon: focused || value.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: padding.left,
                      ),
                      Text(
                        widget.decoration!.prefixText!,
                        style: baseStyle,
                        maxLines: 1,
                      ),
                    ],
                  )
                : null,
          );
    } else {
      return decoration;
    }
  }
}
