import 'package:ln_forms/ln_forms.dart';
import 'package:flutter/material.dart';

export 'ln_form.dart';
export 'input_form_field.dart';
export 'copyable.dart';

export 'fields/checkbox_form_field.dart';
export 'fields/date_input_form_field.dart';
export 'fields/dropdown_form_field.dart';
export 'fields/html_editor_form_field.dart';
export 'fields/image_picker_form_field.dart';
export 'fields/multi_select_form_field.dart';
export 'fields/multiple_text_input_form_field.dart';
export 'fields/non_editable_field.dart';
export 'fields/phone_number_input_form_field.dart';
export 'fields/select_form_field.dart';
export 'fields/text_input_form_field.dart';
export 'fields/time_input_form_field.dart';

export 'input_formatters/special_text_editing_controller.dart';
export 'input_formatters/upper_case_text_formatter.dart';

class NullImportant extends Widget {
  const NullImportant({super.key});

  @override
  Element createElement() {
    throw Exception("This widget should never create!");
  }
}

class LnDecoration {
  final String? label;
  final String? hint;
  final String? helper;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? counter;
  final String? error;

  const LnDecoration({
    this.label,
    this.hint,
    this.helper,
    this.prefixText,
    this.prefixIcon,
    this.suffixIcon,
    this.counter,
    this.error,
  });

  static Widget get nullImportant => const NullImportant();

  LnDecoration applyDefaults(LnDecoration dec) {
    return LnDecoration(
      label: label ?? dec.label,
      hint: hint ?? dec.hint,
      helper: helper ?? dec.helper,
      prefixText: prefixText ?? dec.prefixText,
      prefixIcon: prefixIcon ?? dec.prefixIcon,
      suffixIcon: suffixIcon ?? dec.suffixIcon,
      counter: counter ?? dec.counter,
      error: error ?? dec.error,
    );
  }

  LnDecoration copyWith({
    String? label,
    String? hint,
    String? helper,
    String? prefixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? counter,
    String? error,
  }) {
    return LnDecoration(
      label: label ?? this.label,
      hint: hint ?? this.hint,
      helper: helper ?? this.helper,
      prefixText: prefixText ?? this.prefixText,
      prefixIcon: this.prefixIcon is NullImportant
          ? this.prefixIcon
          : prefixIcon ?? this.prefixIcon,
      suffixIcon: this.suffixIcon is NullImportant
          ? this.suffixIcon
          : suffixIcon ?? this.suffixIcon,
      counter: counter ?? this.counter,
      error: error ?? this.error,
    );
  }

  LnDecoration apply({
    Wrapped<String?>? label,
    Wrapped<String?>? hint,
    Wrapped<String?>? helper,
    Wrapped<String?>? prefixText,
    Wrapped<Widget?>? prefixIcon,
    Wrapped<Widget?>? suffixIcon,
    Wrapped<String?>? counter,
    Wrapped<String?>? error,
  }) {
    return LnDecoration(
      label: label == null ? this.label : label.value,
      hint: hint == null ? this.hint : hint.value,
      helper: helper == null ? this.helper : helper.value,
      prefixText: prefixText == null ? this.prefixText : prefixText.value,
      prefixIcon: prefixIcon == null || this.prefixIcon is NullImportant
          ? this.prefixIcon
          : prefixIcon.value,
      suffixIcon: suffixIcon == null || this.suffixIcon is NullImportant
          ? this.suffixIcon
          : suffixIcon.value,
      counter: counter == null ? this.counter : counter.value,
      error: error?.value ?? this.error,
    );
  }

  InputDecoration build() {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixText: prefixText,
      prefixIcon: prefixIcon is NullImportant ? null : prefixIcon,
      suffixIcon: suffixIcon is NullImportant ? null : suffixIcon,
      counterText: counter,
      errorText: error,
    );
  }
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}

class InputOption {
  final String label;
  final dynamic value;

  InputOption(this.label, this.value);
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
        _ => throw Exception("Undefined input type")
      };
}
