import 'package:flutter/material.dart';

class EmptyReadOnlyField extends Align {
  EmptyReadOnlyField({
    super.key,
    final Color? color,
  }) : super(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 24, height: 1.5),
            child: Divider(
              height: 1.5,
              thickness: 1.5,
              color: color,
            ),
          ),
        );
}
