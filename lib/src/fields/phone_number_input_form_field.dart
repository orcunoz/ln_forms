import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
export 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PhoneNumberInputFormField extends TextInputFormField {
  static final _inputFormatter = MaskTextInputFormatter(
    mask: '(###) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  PhoneNumberInputFormField({
    super.key,
    super.focusNode,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    Function(String?)? onChanged,
    super.onSaved,
    super.autofocus,
    super.textInputAction,
    super.validator,
    String? initialValue,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
    int countryCode = 90,
  }) : super(
          decoration: decoration?.copyWith(
            suffixIcon:
                decoration.suffixIcon ?? const Icon(Icons.add_ic_call_rounded),
            prefixText: "+$countryCode ",
          ),
          inputFormatters: [
            _inputFormatter,
          ],
          keyboardType: TextInputType.phone,
          initialValue: initialValue == null
              ? null
              : _inputFormatter.maskText(initialValue),
          onChanged: (val) => onChanged?.call(
            val == null ? null : _inputFormatter.unmaskText(val),
          ),
        );
}
