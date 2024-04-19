import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BottomNotifierScrollController extends OverlimitScrollController {
  BottomNotifierScrollController() : super(keepScrollOffset: true) {
    addListener(() {
      _atTheBottomNotifier.value = position.maxScrollExtent - offset == 0;
    });
  }

  final ValueNotifier<bool> _atTheBottomNotifier = ValueNotifier<bool>(false);
  ValueListenable<bool> get atTheBottomListener => _atTheBottomNotifier;
  bool get atTheBottom => _atTheBottomNotifier.value;

  void addAtTheBottomListener(VoidCallback listener) {
    _atTheBottomNotifier.addListener(listener);
  }

  void removeAtTheBottomListener(VoidCallback listener) {
    _atTheBottomNotifier.removeListener(listener);
  }
}

class OverlimitScrollView extends StatefulWidget {
  const OverlimitScrollView({
    super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.primary,
    this.physics,
    this.controller,
    this.child,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final OverlimitScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final Widget? child;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  @override
  State<OverlimitScrollView> createState() => _OverlimitScrollViewState();
}

class _OverlimitScrollViewState extends State<OverlimitScrollView> {
  OverlimitScrollController? _internalController;
  OverlimitScrollController get effectiveController =>
      widget.controller ?? _internalController!;

  double? _overflowY;
  Duration? _duration;
  Curve? _curve;

  @override
  void initState() {
    super.initState();

    (widget.controller ?? (_internalController = OverlimitScrollController()))
        .addOverlimitListener(_handleOverlimitScroll);
  }

  @override
  void dispose() {
    effectiveController.removeOverlimitListener(_handleOverlimitScroll);
    _internalController?.dispose();
    super.dispose();
  }

  void _handleOverlimitScroll(double overflowY,
      [Duration? animationDuration, Curve? animationCurve]) {
    setState(() {
      _overflowY = overflowY;
      _duration = animationDuration ?? _duration;
      _curve = animationCurve ?? _curve;
    });
  }

  @override
  void didUpdateWidget(covariant OverlimitScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeOverlimitListener(_handleOverlimitScroll);
      widget.controller?.addOverlimitListener(_handleOverlimitScroll);

      if (oldWidget.controller != null && widget.controller == null) {
        _internalController = OverlimitScrollController()
          ..addOverlimitListener(_handleOverlimitScroll);
      }

      if (widget.controller != null && oldWidget.controller == null) {
        _internalController
          ?..removeOverlimitListener(_handleOverlimitScroll)
          ..dispose();
        _internalController = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveController = widget.controller ?? _internalController!;
    final nnOverlimitY = _overflowY ?? 0;
    return SingleChildScrollView(
      controller: effectiveController,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      padding: widget.padding,
      primary: widget.primary,
      physics: widget.physics,
      dragStartBehavior: widget.dragStartBehavior,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      child: AnimatedContainer(
        transform: Matrix4.translationValues(0, nnOverlimitY, 0),
        duration: _duration ?? Duration.zero,
        curve: _curve ?? Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

typedef OverlimitScrollListener = void Function(
  double overflowY, [
  Duration? animationDuration,
  Curve? animationCurve,
]);

class OverlimitScrollPositionWithSingleContext
    extends ScrollPositionWithSingleContext {
  final OverlimitScrollListener listener;
  OverlimitScrollPositionWithSingleContext({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
    required this.listener,
  });

  double _limitOffsetAndNotifyOverlimit(
    double requestedOffset, [
    Duration? animationDuration,
    Curve? animationCurve,
  ]) {
    final double offset, overlimitOffset;

    if (requestedOffset < 0) {
      offset = 0;
      overlimitOffset = -requestedOffset;
    } else if (requestedOffset > maxScrollExtent) {
      offset = maxScrollExtent;
      overlimitOffset = maxScrollExtent - requestedOffset;
    } else {
      offset = requestedOffset;
      overlimitOffset = 0;
    }

    listener(overlimitOffset, animationDuration, animationCurve);
    return offset;
  }

  void removeOverlimitOffset() => listener(0);

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) =>
      super.animateTo(
        _limitOffsetAndNotifyOverlimit(to, duration, curve),
        duration: duration,
        curve: curve,
      );

  /*@override
  void jumpTo(double value) =>
      super.jumpTo(_limitOffsetAndNotifyOverlimit(value));

  @override
  void jumpToWithoutSettling(double value) =>
      // ignore: deprecated_member_use
      super.jumpToWithoutSettling(_limitOffsetAndNotifyOverlimit(value));*/
}

class OverlimitScrollController extends ScrollController {
  OverlimitScrollController({
    super.initialScrollOffset = 0.0,
    super.keepScrollOffset = true,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  final Set<OverlimitScrollListener> _listeners = <OverlimitScrollListener>{};

  void _notifyOverlimitListeners(double offsetY,
      [Duration? duration, Curve? curve]) {
    for (var listener in _listeners) {
      listener(offsetY, duration, curve);
    }
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition? oldPosition) {
    return OverlimitScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
      listener: _notifyOverlimitListeners,
    );
  }

  void addOverlimitListener(OverlimitScrollListener listener) {
    _listeners.add(listener);
  }

  void removeOverlimitListener(OverlimitScrollListener listener) {
    _listeners.remove(listener);
  }
}
