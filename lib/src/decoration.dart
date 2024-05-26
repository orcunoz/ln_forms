import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

class LnDecoration {
  final String? label;
  final String? hint;
  final String? helper;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? counter;
  final String? error;

  static const nullImportant = UnusableWidget(
    invalidUsageMessage: "This widget should never create!",
  );

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
      prefixIcon: prefixIcon ?? this.prefixIcon,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      counter: counter ?? this.counter,
      error: error ?? this.error,
    );
  }

  LnDecoration apply({
    Value<String?>? label,
    Value<String?>? hint,
    Value<String?>? helper,
    Value<String?>? prefixText,
    Value<Widget?>? prefixIcon,
    Value<Widget?>? suffixIcon,
    Value<String?>? counter,
    Value<String?>? error,
  }) {
    return LnDecoration(
      label: label == null ? this.label : label.value,
      hint: hint == null ? this.hint : hint.value,
      helper: helper == null ? this.helper : helper.value,
      prefixText: prefixText == null ? this.prefixText : prefixText.value,
      prefixIcon: prefixIcon == null ? this.prefixIcon : prefixIcon.value,
      suffixIcon: suffixIcon == null ? this.suffixIcon : suffixIcon.value,
      counter: counter == null ? this.counter : counter.value,
      error: error == null ? this.error : error.value,
    );
  }

  InputDecoration build() {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixText: prefixText,
      prefixIcon: prefixIcon == nullImportant ? null : prefixIcon,
      suffixIcon: suffixIcon == nullImportant ? null : suffixIcon,
      counterText: counter,
      errorText: error,
    );
  }
}
