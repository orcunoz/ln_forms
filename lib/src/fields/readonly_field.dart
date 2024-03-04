import 'package:flutter/material.dart';
import 'package:ln_forms/ln_forms.dart';

class ReadOnlyField extends LnSimpleField<String?> {
  ReadOnlyField({
    super.key,
    super.value,
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
          focusNode: FocusNode(
            canRequestFocus: false,
            skipTraversal: true,
            descendantsAreTraversable: false,
            descendantsAreFocusable: false,
          ),
          builder: (field, computedState) {
            return Text(value ?? "");
          },
          emptyValue: null,
        );
}
