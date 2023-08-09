import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef NodeGenerator = FocusNode Function(int index);

extension FocusNodeSetExtensions on Set<FocusNode> {
  void grow(int length, NodeGenerator? generator) {
    generator ??= (index) => FocusNode();
    while (length > this.length) {
      add(generator(this.length));
    }
  }
}

extension FocusNodeListExtensions on List<FocusNode> {
  void grow(int length, NodeGenerator? generator) {
    generator ??= (index) => FocusNode();
    while (length > this.length) {
      add(generator(this.length));
    }
  }
}

extension FocusNodeIterableExtensions on Iterable<FocusNode> {
  void disposeAll() {
    for (var fn in this) {
      fn.dispose();
    }
  }
}

extension RenderObjectExtensions on RenderObject {
  Future<void> ensureVisible(
    ScrollPosition scrollPosition, {
    Duration duration = const Duration(milliseconds: 100),
    Curve curve = Curves.easeIn,
  }) {
    final viewport = RenderAbstractViewport.of(this);

    late double alignment;

    if (scrollPosition.pixels > viewport.getOffsetToReveal(this, 0.0).offset) {
      // Move down to the top of the viewport
      alignment = 0.0;
    } else if (scrollPosition.pixels <
        viewport.getOffsetToReveal(this, 1.0).offset) {
      // Move up to the bottom of the viewport
      alignment = 1.0;
    } else {
      return Future.value(null);
    }

    return scrollPosition.ensureVisible(
      this,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }
}
