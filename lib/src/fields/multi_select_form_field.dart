import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';

class MultiSelectFormField<ItemType> extends InputFormField<List<ItemType>> {
  final Iterable<ItemType> items;
  final String Function(ItemType?) itemLabelBuilder;
  final Widget? Function(List<ItemType>? value)? labelBuilder;
  final bool searchable;
  final bool showCloseButton;

  MultiSelectFormField({
    super.key,
    super.onChanged,
    super.onSaved,
    super.readOnly,
    super.enabled,
    super.focusNode,
    this.searchable = false,
    this.showCloseButton = true,
    required super.initialValue,
    required this.items,
    required this.itemLabelBuilder,
    this.labelBuilder,
    super.validate,
    super.clearable,
    super.restoreable,
    super.style,
    super.decoration,
  }) : super(
          useFocusNode: true,
          builder: (InputFormFieldState<List<ItemType>> field) {
            return labelBuilder != null
                ? labelBuilder(field.value)
                : Text(
                    (field.value ?? const [])
                        .map((selectedItem) => itemLabelBuilder(selectedItem))
                        .join(", "),
                  );
          },
        );

  @override
  MultiSelectFormFieldState<ItemType> createState() {
    return MultiSelectFormFieldState<ItemType>();
  }
}

class MultiSelectFormFieldState<ItemType>
    extends InputFormFieldState<List<ItemType>>
    with FutureFormField<List<ItemType>> {
  @override
  MultiSelectFormField<ItemType> get widget =>
      super.widget as MultiSelectFormField<ItemType>;

  @override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 36),
      );

  @override
  Future<List<ItemType>?> toFuture() {
    return MultiSelectionDialog.show(
      context: context,
      title: widget.decoration?.label ?? widget.decoration?.hint ?? "",
      items: widget.items,
      itemLabelBuilder: widget.itemLabelBuilder,
      showCloseButton: widget.showCloseButton,
      searchable: widget.searchable,
    );
  }
}
