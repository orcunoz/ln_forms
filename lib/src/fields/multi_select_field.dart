import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';

class MultiSelectField<ItemType> extends LnSimpleFutureField<List<ItemType>> {
  MultiSelectField({
    super.key,
    super.onChanged,
    super.onSaved,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.focusNode,
    this.searchable = false,
    this.showCloseButton = true,
    super.value = const [],
    super.controller,
    required this.items,
    required this.itemLabelBuilder,
    this.labelBuilder,
    super.validator,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
  }) : super(
          useFocusNode: true,
          decoration: decoration?.copyWith(
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 36),
          ),
          builder: (field, computedState) {
            return labelBuilder != null
                ? labelBuilder(field.value)
                : Text(
                    field.value
                        .map((selectedItem) => itemLabelBuilder(selectedItem))
                        .join(", "),
                  );
          },
          emptyValue: [],
          onTrigger: _onTrigger,
        );

  final Iterable<ItemType> items;
  final String Function(ItemType?) itemLabelBuilder;
  final Widget? Function(List<ItemType>? value)? labelBuilder;
  final bool searchable;
  final bool showCloseButton;

  static Future<List<ItemType>?> _onTrigger<ItemType>(
      LnFutureFieldState<List<ItemType>, List<ItemType>> state) {
    final field = state.widget as MultiSelectField<ItemType>;

    return MultiSelectionDialog.show(
      context: state.context,
      title: field.decoration?.label ?? field.decoration?.hint ?? "",
      items: field.items,
      itemLabelBuilder: field.itemLabelBuilder,
      showCloseButton: field.showCloseButton,
      searchable: field.searchable,
    );
  }
}
