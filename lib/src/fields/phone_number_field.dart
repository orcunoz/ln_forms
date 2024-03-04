import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
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
            prefixText: "+$countryCode ",
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
}
