import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';

enum SelectionListType {
  dropdown,
  dialog,
  fixedUnder,
}

class SelectionFormField<ItemType> extends InputFormField<ItemType> {
  final bool searchable;
  final String Function(ItemType?) itemLabelBuilder;
  final Iterable<ItemType> items;
  final bool? shrinkWrap;
  final SelectionListType selectionType;

  SelectionFormField({
    super.key,
    required super.initialValue,
    super.onChanged,
    super.onSaved,
    super.validate,
    super.readOnly,
    super.enabled,
    super.clearable,
    super.restoreable,
    super.focusNode,
    super.style,
    super.decoration,
    required this.items,
    required this.itemLabelBuilder,
    this.searchable = false,
    this.shrinkWrap,
    this.selectionType = SelectionListType.dropdown,
  }) : super(
          useFocusNode: true,
          builder: (InputFormFieldState<ItemType> field) {
            return Text(
              itemLabelBuilder(field.value),
            );
          },
        );

  @override
  SelectionFormFieldState<ItemType> createState() {
    return SelectionFormFieldState<ItemType>();
  }
}

class SelectionFormFieldState<ItemType> extends InputFormFieldState<ItemType>
    with FutureFormField<ItemType> {
  @override
  SelectionFormField<ItemType> get widget =>
      super.widget as SelectionFormField<ItemType>;

  @override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 36),
      );

  @override
  Future<ItemType?> toFuture() {
    return SelectionDialog.show<ItemType>(
      context: context,
      title: widget.decoration?.label ?? widget.decoration?.hint ?? "",
      items: widget.items,
      itemLabelBuilder: widget.itemLabelBuilder,
      searchable: widget.searchable,
      selectedItem: widget.initialValue,
      shrinkWrap: widget.shrinkWrap,
    );
  }
}
