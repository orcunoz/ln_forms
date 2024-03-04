import 'package:flutter/material.dart';

class EmptyReadOnlyField extends Builder {
  EmptyReadOnlyField({
    super.key,
  }) : super(
          builder: (context) => Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints.tightFor(width: 24, height: 1.5),
              child: Divider(
                height: 1.5,
                thickness: 1.5,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        );
}
