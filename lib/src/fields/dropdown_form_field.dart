import 'package:flutter/material.dart' hide DropdownButton;
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/widgets/dropdown_button.dart';
import 'package:ln_core/ln_core.dart';

class DropdownFormField<ItemType> extends InputFormField<ItemType> {
  final String Function(ItemType?) itemLabelBuilder;
  final List<ItemType> items;
  final bool? shrinkWrap;
  final bool showRadioButtons;
  final double? fixedListWidth;

  DropdownFormField({
    super.key,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.validate,
    super.readOnly,
    super.enabled,
    super.clearable,
    super.restoreable,
    super.focusNode,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
    required this.items,
    required this.itemLabelBuilder,
    bool? searchable,
    this.shrinkWrap,
    this.showRadioButtons = true,
    this.fixedListWidth,
  }) : super(
          useFocusNode: true,
          absorbInsideTapEvents: true,
          decoration: decoration,
          builder: (InputFormFieldState<ItemType> field) {
            final state = field as _DropdownFormFieldState<ItemType>;

            final effectiveContentPadding =
                state.effectiveDecoration.contentPadding?.at(state.context) ??
                    EdgeInsets.zero;

            InputBorder? focusedBorder = (state.isPassed && state.hasError
                ? state.effectiveDecoration.focusedErrorBorder
                : state.effectiveDecoration.focusedBorder);
            focusedBorder = focusedBorder?.copyWith(
              borderSide: focusedBorder.borderSide.copyWith(
                color: focusedBorder.borderSide.color.blend(
                    state.effectiveDecoration.fillColor ??
                        focusedBorder.borderSide.color,
                    90),
              ),
            );

            final renderObject = state.context.findRenderObject();
            final buttonWidth = (renderObject as RenderBox?)?.size.width;

            return DropdownButton<ItemType>(
              key: state.buttonKey,
              items: items,
              itemLabelBuilder: itemLabelBuilder,
              focusNode: state.uselessNode,
              onTap: state.isActive ? state.handleTap : null,
              enabled: state.isActive,
              fixedWidth:
                  fixedListWidth ?? (state.value == null ? buttonWidth : null),
              style: state.baseTextStyle,
              value: state.value,
              hintText: decoration?.hint,
              menuMaxHeight: 500,
              searchable: searchable ?? items.length > 10,
              focusColor: state.effectiveDecoration.fillColor,
              itemPadding: effectiveContentPadding,
              alignment: Alignment.centerLeft,
              focusedBorder: focusedBorder,
              dropdownPosition: DropdownPosition.over,
            );
          },
        );

  @override
  InputFormFieldState<ItemType> createState() {
    return _DropdownFormFieldState<ItemType>();
  }
}

class _DropdownFormFieldState<ItemType> extends InputFormFieldState<ItemType>
    with FutureFormField<ItemType>, WidgetsBindingObserver {
  @override
  DropdownFormField<ItemType> get widget =>
      super.widget as DropdownFormField<ItemType>;

  final GlobalKey<DropdownButtonState<ItemType>> buttonKey = GlobalKey();

  final FocusNode uselessNode = FocusNode(
    canRequestFocus: true,
    skipTraversal: true,
  );

  @override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: Transform.scale(
          scale: 1.6,
          child: const Icon(Icons.arrow_drop_down_rounded),
        ),
      );

  @override
  InputDecoration get effectiveDecoration =>
      widget.decoration?.hint?.isNotEmpty == true
          ? super
              .effectiveDecoration
              .copyWith(floatingLabelBehavior: FloatingLabelBehavior.always)
          : super.effectiveDecoration;

  @override
  Future<ItemType?> toFuture() {
    return Future.delayed(const Duration(milliseconds: 100),
        () => buttonKey.currentState!.showMenu().catchError((e) => null));
  }
}
