import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:intl/intl.dart';
import 'package:ln_forms/src/locales/form_localizations.dart';

class DateInputFormField extends InputFormField<DateTime> {
  final DateTime? firstDate;
  final DateTime? lastDate;

  DateInputFormField({
    super.key,
    super.onChanged,
    super.onSaved,
    super.readOnly,
    super.enabled,
    super.initialValue,
    this.firstDate,
    this.lastDate,
    super.focusNode,
    super.validator,
    super.clearable,
    super.restoreable,
    super.style,
    super.decoration,
  }) : super(
          useFocusNode: true,
          builder: (InputFormFieldState<DateTime> field) {
            final dateFormat = DateFormat.yMMMd(_languageCodeOf(field.context));
            return field.value == null
                ? null
                : Text(dateFormat.format(field.value!));
          },
        );

  static String _languageCodeOf(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  @override
  InputFormFieldState<DateTime> createState() {
    return _DateInputFormFieldState();
  }
}

class _DateInputFormFieldState extends InputFormFieldState<DateTime>
    with FutureFormField<DateTime> {
  @override
  DateInputFormField get widget => super.widget as DateInputFormField;

  @override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: const Icon(Icons.calendar_month_rounded),
      );

  @override
  Future<DateTime?> toFuture() {
    final now = DateTime.now();
    final firstDate =
        widget.firstDate ?? now.add(const Duration(days: -365 * 10));
    final lastDate = widget.lastDate ?? now.add(const Duration(days: 365 * 10));
    final initialDate = value ?? now;

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate.isBefore(initialDate) ? firstDate : initialDate,
      lastDate: lastDate.isAfter(initialDate) ? lastDate : initialDate,
      locale: Localizations.localeOf(context),
      fieldLabelText: widget.decoration?.label,
      fieldHintText: widget.decoration?.hint,
      helpText: widget.decoration?.helper,
      confirmText: formLocalizations.current.confirmButton,
      cancelText: formLocalizations.current.cancelButton,
    );
  }
}
