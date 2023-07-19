import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

import 'form.dart';

enum LnFormActionButtonType {
  edit,
  save,
  cancelEditing,
  restore,
  clear,
}

class LnFormActionButton {
  final LnFormActionButtonType? type;
  final String? text;
  final Widget? icon;
  final String? tooltip;
  final void Function()? onPressed;
  final List<FormMode> enabledModes;

  const LnFormActionButton({
    this.text,
    this.icon,
    this.tooltip,
    this.onPressed,
    required this.enabledModes,
  })  : assert(text != null || icon != null),
        type = null;

  const LnFormActionButton.edit({
    this.text,
    this.icon,
    this.tooltip,
  })  : type = LnFormActionButtonType.edit,
        onPressed = null,
        enabledModes = const [FormMode.view];

  const LnFormActionButton.save({
    this.text,
    this.icon,
    this.tooltip,
  })  : type = LnFormActionButtonType.save,
        onPressed = null,
        enabledModes = const [FormMode.edit];

  const LnFormActionButton.cancelEditing({
    this.text,
    this.icon,
    this.tooltip,
  })  : type = LnFormActionButtonType.cancelEditing,
        onPressed = null,
        enabledModes = const [FormMode.edit];

  const LnFormActionButton.restore({
    this.text,
    this.icon,
    this.tooltip,
  })  : type = LnFormActionButtonType.restore,
        onPressed = null,
        enabledModes = const [FormMode.edit];

  const LnFormActionButton.clear({
    this.text,
    this.icon,
    this.tooltip,
  })  : type = LnFormActionButtonType.clear,
        onPressed = null,
        enabledModes = const [FormMode.edit];

  Widget build({
    required BuildContext context,
    required bool short,
    required bool primary,
    required bool busy,
    required bool enabled,
    FocusNode? focusNode,
    void Function()? onPressed,
  }) {
    assert(type == null || this.onPressed == null);
    final compOnPressed =
        enabled && !busy ? (type == null ? this.onPressed : onPressed) : null;
    if (short) {
      if (primary) {
        return IconButton.filled(
          onPressed: compOnPressed,
          icon: icon!,
          tooltip: text,
          focusNode: focusNode,
        );
      } else {
        final theme = Theme.of(context);
        return IconButton(
          onPressed: compOnPressed,
          icon: icon!,
          tooltip: text,
          focusNode: focusNode,
          style: (theme.iconButtonTheme.style ?? ButtonStyle())
              .copyWith(iconColor: theme.colorScheme.primary.material),
        );
      }
    } else {
      if (primary) {
        return FilledButton.icon(
          onPressed: compOnPressed,
          icon: icon!,
          label: Text(text!),
          focusNode: focusNode,
        );
      } else {
        final theme = Theme.of(context);
        return TextButton.icon(
          onPressed: compOnPressed,
          icon: icon!,
          label: Text(text!),
          focusNode: focusNode,
          style: (theme.iconButtonTheme.style ?? ButtonStyle())
              .copyWith(iconColor: theme.colorScheme.primary.material),
        );
      }
    }
  }
}
