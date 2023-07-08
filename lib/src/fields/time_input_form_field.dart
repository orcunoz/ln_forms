import 'package:flutter/material.dart';
import '../ln_forms_base.dart';

class TimeInputFormField extends InputFormField<TimeOfDay> {
  TimeInputFormField({
    super.key,
    super.readOnly,
    super.enabled,
    required super.initialValue,
    super.onChanged,
    super.onSaved,
    super.focusNode,
    super.validate,
    super.clearable,
    super.restoreable,
    super.style,
    LnDecoration? decoration,
  }) : super(
          decoration: (decoration ?? const LnDecoration()).copyWith(
              suffixIcon: decoration?.suffixIcon ??
                  const Icon(Icons.access_time_rounded)),
          useFocusNode: true,
          builder: (InputFormFieldState<TimeOfDay> field) {
            return Text(
              field.value?.format(field.context) ?? "",
            );
          },
        );

  @override
  InputFormFieldState<TimeOfDay> createState() {
    return _TimeInputFormFieldState();
  }
}

class _TimeInputFormFieldState extends InputFormFieldState<TimeOfDay>
    with FutureFormField<TimeOfDay> {
  @override
  TimeInputFormField get widget => super.widget as TimeInputFormField;

  @override
  Future<TimeOfDay?> toFuture() {
    return showTimePicker(
      context: context,
      initialTime: widget.initialValue ?? TimeOfDay.now(),
      helpText: widget.decoration?.label,
      //confirmText: S.of(context).dialogConfirm,
      //cancelText: S.of(context).dialogCancel,
    );
  }
}
