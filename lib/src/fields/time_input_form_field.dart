import 'package:flutter/material.dart';

import '../decoration.dart';
import '../form.dart';
import '../localization/forms_localizations.dart';

class TimeInputFormField extends LnFormField<TimeOfDay> {
  TimeInputFormField({
    super.key,
    super.enabled = true,
    super.readOnly = false,
    super.clearable = true,
    super.restoreable = true,
    required super.initialValue,
    super.onChanged,
    super.onSaved,
    super.focusNode,
    super.validator,
    super.style,
    super.decoration,
  }) : super(
          useFocusNode: true,
          builder: (LnFormFieldState<TimeOfDay> field) => Text(
            field.value?.format(field.context) ?? "",
          ),
        );

  @override
  LnFormFieldState<TimeOfDay> createState() {
    return _TimeInputFormFieldState();
  }
}

class _TimeInputFormFieldState extends LnFormFieldState<TimeOfDay>
    with FutureFormField<TimeOfDay> {
  @override
  TimeInputFormField get widget => super.widget as TimeInputFormField;

  @override
  LnDecoration get baseDecoration => LnDecoration(
      suffixIcon: widget.decoration?.suffixIcon ??
          const Icon(Icons.access_time_rounded));

  @override
  Future<TimeOfDay?> toFuture() {
    return showTimePicker(
      context: context,
      initialTime: widget.initialValue ?? TimeOfDay.now(),
      helpText: widget.decoration?.label,
      confirmText: LnFormsLocalizations.current.confirmButton,
      cancelText: LnFormsLocalizations.current.cancelButton,
    );
  }
}
