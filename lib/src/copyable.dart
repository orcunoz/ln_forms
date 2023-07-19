import 'package:flutter/widgets.dart';

mixin Copyable<T> {
  @required
  T copy();
}

final class VoidCopyable with Copyable<VoidCopyable> {
  @override
  VoidCopyable copy() => this;
}
