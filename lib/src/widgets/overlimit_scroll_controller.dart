// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';

class _OverlimitScrollScope extends InheritedWidget {
  final OverlimitScrollControllerState state;

  const _OverlimitScrollScope({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_OverlimitScrollScope oldWidget) =>
      state != oldWidget.state;
}

class OverlimitScrollController extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const OverlimitScrollController({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<OverlimitScrollController> createState() =>
      OverlimitScrollControllerState();

  static OverlimitScrollControllerState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_OverlimitScrollScope>()
        ?.state;
  }
}

class OverlimitScrollControllerState extends State<OverlimitScrollController>
    implements ScrollController {
  Duration? _animationDuration;
  Curve? _animationCurve;
  double? _overflowY;

  (double, double) parseAndLimitOffset(double offset) => offset < 0
      ? (0, -offset)
      : offset > widget.controller.position.maxScrollExtent
          ? (
              widget.controller.position.maxScrollExtent,
              widget.controller.position.maxScrollExtent - offset
            )
          : (offset, 0);

  void removeOverlimitOffset() {
    setState(() {
      _overflowY = null;
    });
  }

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) async {
    final double overflowOffset;
    (offset, overflowOffset) = parseAndLimitOffset(offset);

    setState(() {
      _overflowY = overflowOffset;
      _animationDuration = duration;
      _animationCurve = curve;
      widget.controller.animateTo(offset, duration: duration, curve: curve);
    });
  }

  @override
  void jumpTo(double value) {
    final double overflowOffset;
    (value, overflowOffset) = parseAndLimitOffset(value);

    setState(() {
      _overflowY = overflowOffset;
      _animationDuration = Duration.zero;
      _animationCurve = Curves.easeInOut;
      widget.controller.jumpTo(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _OverlimitScrollScope(
      state: this,
      child: AnimatedContainer(
        transform: Matrix4.translationValues(0, _overflowY ?? 0, 0),
        duration: _animationDuration ?? Duration.zero,
        curve: _animationCurve ?? Curves.easeInOut,
        child: widget.child,
      ),
    );
  }

  @override
  void addListener(VoidCallback listener) {
    widget.controller.addListener(listener);
  }

  @override
  void attach(ScrollPosition position) {
    widget.controller.attach(position);
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return widget.controller
        .createScrollPosition(physics, context, oldPosition);
  }

  @override
  void debugFillDescription(List<String> description) {
    widget.controller.debugFillDescription(description);
  }

  @override
  String? get debugLabel => widget.controller.debugLabel;

  @override
  void detach(ScrollPosition position) {
    widget.controller.detach(position);
  }

  @override
  bool get hasClients => widget.controller.hasClients;

  @override
  bool get hasListeners => widget.controller.hasListeners;

  @override
  double get initialScrollOffset => widget.controller.initialScrollOffset;

  @override
  bool get keepScrollOffset => widget.controller.keepScrollOffset;

  @override
  void notifyListeners() {
    widget.controller.notifyListeners();
  }

  @override
  double get offset => widget.controller.offset;

  @override
  ScrollPosition get position => widget.controller.position;

  @override
  Iterable<ScrollPosition> get positions => widget.controller.positions;

  @override
  void removeListener(VoidCallback listener) {
    widget.controller.removeListener(listener);
  }
}
