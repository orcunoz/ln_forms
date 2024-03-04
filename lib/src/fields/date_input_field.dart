import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:intl/intl.dart';

class DateInputField extends LnSimpleFutureField<DateTime?> {
  DateInputField({
    super.key,
    super.onChanged,
    super.onSaved,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.value,
    super.controller,
    this.firstDate,
    this.lastDate,
    super.focusNode,
    super.validator,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
  }) : super(
          useFocusNode: true,
          decoration: decoration?.copyWith(
            suffixIcon: const Icon(Icons.calendar_month_rounded),
          ),
          builder: (field, computedState) {
            final valueText = switch (field.value) {
              null => "",
              _ => DateFormat.yMMMd(_languageCodeOf(field.context))
                  .format(field.value!),
            };
            return Text(valueText);
          },
          emptyValue: null,
          onTrigger: _onTrigger,
        );

  final DateTime? firstDate;
  final DateTime? lastDate;

  static String _languageCodeOf(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  static Future<DateTime?> _onTrigger(
      LnSimpleFutureFieldState<DateTime?> state) {
    final field = state.widget as DateInputField;
    const tenYear = Duration(days: 365 * 10);
    final now = DateTime.now();
    final firstDate = field.firstDate ?? now.subtract(tenYear);
    final lastDate = field.lastDate ?? now.add(tenYear);
    final initialDate = state.value ?? now;

    return showDatePicker(
      context: state.context,
      initialDate: initialDate,
      firstDate: firstDate.isBefore(initialDate) ? firstDate : initialDate,
      lastDate: lastDate.isAfter(initialDate) ? lastDate : initialDate,
      locale: Localizations.localeOf(state.context),
      fieldLabelText: field.decoration?.label,
      fieldHintText: field.decoration?.hint,
      helpText: field.decoration?.helper,
      confirmText: LnFormsLocalizations.current.confirmButton,
      cancelText: LnFormsLocalizations.current.cancelButton,
    );
  }
}
