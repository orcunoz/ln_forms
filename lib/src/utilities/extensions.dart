import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

typedef NodeGenerator = FocusNode Function(int index);

extension FocusNodeSetExtensions on Set<FocusNode> {
  void grow(int length, NodeGenerator? generator) {
    generator ??= (index) => FocusNode();
    while (length > this.length) {
      add(generator(this.length));
    }
  }
}

extension FocusNodeListExtensions on List<FocusNode> {
  void grow(int length, NodeGenerator? generator) {
    generator ??= (index) => FocusNode();
    while (length > this.length) {
      add(generator(this.length));
    }
  }
}

extension FocusNodeIterableExtensions on Iterable<FocusNode> {
  void disposeAll() {
    for (var fn in this) {
      fn.dispose();
    }
  }
}

extension InputDecorationExtensions on InputDecoration {
  InputDecoration apply({
    Value<String?>? label,
    Value<String?>? hint,
    Value<String?>? helper,
    Value<String?>? prefixText,
    Value<Widget?>? prefixIcon,
    Value<Widget?>? suffixIcon,
    Value<String?>? counter,
    Value<String?>? error,
  }) {
    return InputDecoration(
      icon: icon,
      iconColor: iconColor,
      label: this.label,
      labelText: label == null ? labelText : label.value,
      labelStyle: labelStyle,
      floatingLabelStyle: floatingLabelStyle,
      helperText: helper == null ? helperText : helper.value,
      helperStyle: helperStyle,
      helperMaxLines: helperMaxLines,
      hintText: hint == null ? hintText : hint.value,
      hintStyle: hintStyle,
      hintTextDirection: hintTextDirection,
      hintMaxLines: hintMaxLines,
      errorText: error == null ? errorText : error.value,
      errorStyle: errorStyle,
      errorMaxLines: errorMaxLines,
      floatingLabelBehavior: floatingLabelBehavior,
      floatingLabelAlignment: floatingLabelAlignment,
      isCollapsed: isCollapsed,
      isDense: isDense,
      contentPadding: contentPadding,
      prefixIcon: prefixIcon == null ? this.prefixIcon : prefixIcon.value,
      prefixIconConstraints: prefixIconConstraints,
      prefix: prefix,
      prefixText: prefixText == null ? this.prefixText : prefixText.value,
      prefixStyle: prefixStyle,
      prefixIconColor: prefixIconColor,
      suffixIcon: suffixIcon == null ? this.suffixIcon : suffixIcon.value,
      suffix: suffix,
      suffixText: suffixText,
      suffixStyle: suffixStyle,
      suffixIconColor: suffixIconColor,
      suffixIconConstraints: suffixIconConstraints,
      counter: this.counter,
      counterText: counter == null ? counterText : counter.value,
      counterStyle: counterStyle,
      filled: filled,
      fillColor: fillColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      errorBorder: errorBorder,
      focusedBorder: focusedBorder,
      focusedErrorBorder: focusedErrorBorder,
      disabledBorder: disabledBorder,
      enabledBorder: enabledBorder,
      border: border,
      enabled: enabled,
      semanticCounterText: semanticCounterText,
      alignLabelWithHint: alignLabelWithHint,
      constraints: constraints,
    );
  }
}
