import 'package:flutter/material.dart';
import 'package:ln_forms/src/form.dart';

class InputOption {
  final String label;
  final dynamic value;

  const InputOption(this.label, this.value);
}

/*abstract class FormFields {
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
*/

class LnFormBuilder {
  final BuildContext context;
  final ThemeData theme;
  final FormModes mode;

  const LnFormBuilder({
    required this.context,
    required this.theme,
    required this.mode,
  });

  static Widget title(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: theme.inputDecorationTheme.contentPadding ?? EdgeInsets.zero,
      child: Text(
        title,
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
