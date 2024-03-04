import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';

enum SelectionListType {
  dropdown,
  dialog,
  fixedUnder,
}

class SelectionField<ItemType> extends LnSimpleFutureField<ItemType?> {
  SelectionField({
    super.key,
    super.value,
    super.controller,
    super.onChanged,
    super.onSaved,
    super.validator,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.focusNode,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
    required this.items,
    required this.itemLabelBuilder,
    this.searchable = false,
    this.shrinkWrap,
    this.selectionType = SelectionListType.dropdown,
  }) : super(
          useFocusNode: true,
          onTrigger: _onTrigger,
          decoration: decoration?.copyWith(
            suffixIcon: decoration.suffixIcon ??
                const Icon(Icons.arrow_drop_down_rounded, size: 36),
          ),
          builder: (field, scopeProps) {
            return Text(itemLabelBuilder(field.value));
          },
          emptyValue: null,
        );

  final bool searchable;
  final String Function(ItemType?) itemLabelBuilder;
  final Iterable<ItemType> items;
  final bool? shrinkWrap;
  final SelectionListType selectionType;

  static Future<ItemType?> _onTrigger<ItemType>(
      LnSimpleFutureFieldState<ItemType?> state) {
    final field = state.widget as SelectionField<ItemType>;

    return SelectionDialog.show<ItemType>(
      context: state.context,
      title: field.decoration?.label ?? field.decoration?.hint ?? "",
      items: field.items,
      itemLabelBuilder: field.itemLabelBuilder,
      searchable: field.searchable,
      selectedItem: field.value,
      shrinkWrap: field.shrinkWrap,
    );
  }
}
