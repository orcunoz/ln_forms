import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:intl/intl.dart';

class DateInputFormField extends LnFormField<DateTime> {
  final DateTime? firstDate;
  final DateTime? lastDate;

  DateInputFormField({
    super.key,
    super.onChanged,
    super.onSaved,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.initialValue,
    this.firstDate,
    this.lastDate,
    super.focusNode,
    super.validator,
    super.style,
    super.decoration,
  }) : super(
          useFocusNode: true,
          builder: (LnFormFieldState<DateTime> field) {
            final dateFormat = DateFormat.yMMMd(_languageCodeOf(field.context));
            return field.value == null
                ? null
                : Text(dateFormat.format(field.value!));
          },
        );

  static String _languageCodeOf(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  @override
  LnFormFieldState<DateTime> createState() {
    return _DateInputFormFieldState();
  }
}

class _DateInputFormFieldState extends LnFormFieldState<DateTime>
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
      confirmText: LnFormsLocalizations.current.confirmButton,
      cancelText: LnFormsLocalizations.current.cancelButton,
    );
  }
}
