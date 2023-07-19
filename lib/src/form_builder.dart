import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';

class InputOption {
  final String label;
  final dynamic value;

  const InputOption(this.label, this.value);
}

abstract class FormFields {
  static Widget input({
    required String type,
    String? label,
    List<InputOption>? options,
    dynamic initialValue,
    void Function(dynamic)? onChanged,
    bool readOnly = false,
    bool? enabled,
  }) =>
      switch (type) {
        "text" => TextInputFormField(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
          ),
        "date" => DateInputFormField(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
          ),
        "time" => TimeInputFormField(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
          ),
        "select" => DropdownFormField<InputOption>(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
            itemLabelBuilder: (e) => e?.label ?? "",
            items: options!,
          ),
        _ => throw Exception("Undefined input type"),
      };
}
