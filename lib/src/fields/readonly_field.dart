import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';

class ReadOnlyField extends LnSimpleField<void> {
  ReadOnlyField({
    super.key,
    Widget? child,
    super.controller,
    super.style,
    super.decoration = const LnDecoration(),
  }) : super(
          disableGestures: true,
          enabled: true,
          readOnly: false,
          clearable: false,
          restoreable: false,
          useFocusNode: false,
          onChanged: null,
          onSaved: null,
          validator: null,
          value: null,
          focusNode: FocusNode(
            canRequestFocus: false,
            skipTraversal: true,
            descendantsAreTraversable: false,
            descendantsAreFocusable: false,
          ),
          builder: (field, computedState) {
            return child;
          },
          emptyValue: null,
        );
}
