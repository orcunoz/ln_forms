import 'package:flutter/material.dart';

import '../decoration.dart';
import '../form.dart';
import '../localization/forms_localizations.dart';

class TimeInputField extends LnSimpleFutureField<TimeOfDay?> {
  TimeInputField({
    super.key,
    super.enabled = true,
    super.readOnly = false,
    super.clearable = true,
    super.restoreable = true,
    super.value,
    super.controller,
    super.onChanged,
    super.onSaved,
    super.focusNode,
    super.validator,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
  }) : super(
          useFocusNode: true,
          decoration: decoration?.copyWith(
            suffixIcon:
                decoration.suffixIcon ?? const Icon(Icons.access_time_rounded),
          ),
          builder: (field, computedState) => Text(
            field.value?.format(field.context) ?? "",
          ),
          onTrigger: _onTrigger,
          emptyValue: null,
        );

  static Future<TimeOfDay?> _onTrigger(
      LnFormFieldState<TimeOfDay?, TimeOfDay?> field) {
    return showTimePicker(
      context: field.context,
      initialTime: field.value ?? TimeOfDay.now(),
      helpText: field.widget.decoration?.label,
      confirmText: LnFormsLocalizations.current.confirmButton,
      cancelText: LnFormsLocalizations.current.cancelButton,
    );
  }

  @override
  TimeOfDay? get emptyValue => null;
}
