import 'dart:async';

import 'package:flutter/material.dart' hide DropdownButton;
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';

class DropdownField<ItemType> extends LnSimpleFutureField<ItemType> {
  DropdownField({
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
    required List<ItemType> items,
    required String Function(ItemType) itemLabelBuilder,
    bool? searchable,
    bool? shrinkWrap,
    double? fixedListWidth,
  }) : super(
          useFocusNode: true,
          decoration: decoration?.copyWith(
            suffixIcon: Transform.scale(
              scale: 1.6,
              child: const Icon(Icons.arrow_drop_down_rounded),
            ),
          ),
          builder: (field, computedState) {
            field as _DropdownFieldState<ItemType>;

            final compDecoration = field.computedDecoration;
            final effectiveContentPadding =
                compDecoration?.contentPadding?.at(field) ?? EdgeInsets.zero;

            final renderObject = field.context.findRenderObject();
            final buttonWidth = (renderObject as RenderBox?)?.size.width;

            return AbsorbPointer(
              child: DropdownButton<ItemType>(
                key: field.buttonKey,
                items: items,
                itemLabelBuilder: itemLabelBuilder,
                focusNode: field.uselessNode,
                //onTap: computedState.active ? field.handleTap : null,
                enabled: computedState.active,
                fixedWidth: fixedListWidth ??
                    (field.value == null ? buttonWidth : null),
                textStyle: field.baseStyle,
                selectedIndex: _findSelectedIndex(field.value, items),
                hintText: decoration?.hint,
                menuMaxHeight: 500,
                searchable: searchable ?? items.length > 10,
                itemPadding: effectiveContentPadding,
                itemAlignment: Alignment.centerLeft,
                dropdownPosition: DropdownPosition.over,
                //buttonRenderBox: renderObject,
              ),
            );
          },
          emptyValue: null,
          onTrigger: _onTrigger,
        );

  static int? _findSelectedIndex<T>(T? value, List<T> items) {
    if (value is T) {
      var index = items.indexOf(value);
      if (index >= 0) {
        return index;
      }
    }

    return null;
  }

  static Future<ItemType> _onTrigger<ItemType>(
      LnSimpleFutureFieldState<ItemType> state) {
    state as _DropdownFieldState<ItemType>;
    return Future.delayed(
      const Duration(milliseconds: 100),
      state.buttonKey.currentState!.showMenu,
    ).then((newVal) => newVal == null ? state.value : newVal.value);
  }

  @override
  LnSimpleFutureFieldState<ItemType> createState() {
    return _DropdownFieldState<ItemType>();
  }
}

class _DropdownFieldState<ItemType> extends LnSimpleFutureFieldState<ItemType> {
  final GlobalKey<DropdownButtonState<ItemType>> buttonKey = GlobalKey();

  final FocusNode uselessNode = FocusNode(
    canRequestFocus: true,
    skipTraversal: true,
  );

  @override
  InputDecoration? get computedDecoration =>
      widget.decoration?.hint?.isNotEmpty == true
          ? super
              .computedDecoration
              ?.copyWith(floatingLabelBehavior: FloatingLabelBehavior.always)
          : super.computedDecoration;
}
