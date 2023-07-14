import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

class LnFormActionButton {
  final String text;
  final Widget icon;
  final bool forceShowTitle;
  final void Function()? onPressed;

  const LnFormActionButton({
    required this.text,
    required this.icon,
    this.forceShowTitle = false,
    required this.onPressed,
  });

  Widget build({
    required BuildContext context,
    required bool short,
    required bool primary,
    required bool busy,
    required bool enabled,
    FocusNode? focusNode,
  }) {
    final compOnPressed = enabled && !busy ? onPressed : null;
    if (short && !forceShowTitle) {
      if (primary) {
        return IconButton.filled(
          onPressed: compOnPressed,
          icon: icon,
          tooltip: text,
          focusNode: focusNode,
        );
      } else {
        final theme = Theme.of(context);
        return IconButton(
          onPressed: compOnPressed,
          icon: icon,
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
          icon: icon,
          label: Text(text),
          focusNode: focusNode,
        );
      } else {
        final theme = Theme.of(context);
        return TextButton.icon(
          onPressed: compOnPressed,
          icon: icon,
          label: Text(text),
          focusNode: focusNode,
          style: (theme.iconButtonTheme.style ?? ButtonStyle())
              .copyWith(iconColor: theme.colorScheme.primary.material),
        );
      }
    }
  }
}
