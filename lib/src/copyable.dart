import 'package:flutter/widgets.dart';

abstract class Copyable<T> {
  @required
  T copy();
}

class VoidCopyable implements Copyable<VoidCopyable> {
  @override
  VoidCopyable copy() => this;
}
