import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

class NonEditableField extends StatelessWidget {
  final String? labelText;
  final String? text;
  final Widget? child;
  final bool readOnly;
  final bool enabled;
  const NonEditableField({
    super.key,
    this.labelText,
    this.text,
    this.child,
    this.readOnly = false,
    this.enabled = true,
  })  : assert(text != null || child != null),
        assert(text == null || child == null);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).defaultFormFieldStyle;
    final widget = InputDecorator(
      textAlignVertical: TextAlignVertical.center,
      decoration: _prepareDecorationForBuild(context, Theme.of(context)),
      baseStyle: textStyle,
      isHovering: false,
      isFocused: false,
      isEmpty: false,
      child: DefaultTextStyle(
        style: textStyle.copyWith(color: textStyle.color?.withOpacity(0.8)),
        child: child ?? Text(text!),
      ),
    );

    /*final leftPadding = readOnly
        ? theme.inputDecorationTheme.contentPadding?.at(context).left
        : null;
    final widget = Container(
      transform: Matrix4.translationValues(0, -6.2, 0),
      padding: leftPadding != null ? EdgeInsets.only(left: leftPadding) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (labelText != null)
            Text(
              labelText!,
              style: theme.inputDecorationTheme.floatingLabelStyle!.copyWith(
                fontSize: 11.71,
                color: theme.hintColor,
                height: 1,
              ),
            ),
          child ??
              Padding(
                padding: const EdgeInsets.only(top: 7.1),
                child: Text(
                  text!,
                  style: UI.defaultFormFieldTextStyleOf(context),
                ),
              ),
        ],
      ),
    );*/
    return enabled
        ? widget
        : Opacity(
            opacity: 0.5,
            child: widget,
          );
  }

  InputDecoration _prepareDecorationForBuild(
      BuildContext context, ThemeData theme) {
    InputDecoration decoration = InputDecoration(
            labelText: labelText,
            floatingLabelBehavior: FloatingLabelBehavior.always)
        .applyDefaults(theme.inputDecorationTheme)
        .copyWith(
          prefixIconConstraints: const BoxConstraints(
              minHeight: 36, minWidth: kMinInteractiveDimension),
          suffixIconConstraints: const BoxConstraints(
              minHeight: 36, minWidth: kMinInteractiveDimension),
          filled: false,
        );

    if (readOnly) {
      decoration = decoration.copyWith(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            decoration.contentPadding?.at(context).copyWith(left: 0, right: 0),
        border: decoration.readOnlyBorder,
        errorBorder: decoration.readOnlyBorder,
        enabledBorder: decoration.readOnlyBorder,
        focusedBorder: decoration.readOnlyBorder,
        disabledBorder: decoration.readOnlyBorder,
        focusedErrorBorder: decoration.readOnlyBorder,
      );
    }

    return decoration;
  }
}
