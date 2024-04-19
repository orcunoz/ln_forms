import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LnFormFieldGestures extends StatelessWidget {
  const LnFormFieldGestures({
    super.key,
    this.active = true,
    this.onTap,
    this.onPointerEnter,
    this.onPointerExit,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    required this.child,
  });

  final bool active;

  final void Function()? onTap;
  final void Function(PointerEnterEvent)? onPointerEnter;
  final void Function(PointerExitEvent)? onPointerExit;

  final FocusNode? focusNode;
  final bool autofocus;
  final MouseCursor? mouseCursor;
  final Widget child;

  /*@override
  String? get loggerFieldName => widget.loggerFieldName;

  final _hoverNotifier = ValueNotifier<bool>(false);
  Listenable get hoverListenable => _hoverNotifier;
  bool get isHovering => _hoverNotifier.value;
  set _isHovering(bool val) => _hoverNotifier.value = val;

  @mustCallSuper
  void handleTap(PointerDownEvent event) {
    log("handler -> tap");
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @mustCallSuper
  void handleTapOutside(PointerDownEvent event) {
    log("handler -> tapOutside");
    if (widget.onTapOutside != null) {
      widget.onTapOutside!();
    }
  }

  void _handlePointerEnter(PointerEnterEvent event) {
    _isHovering = true;
    if (widget.onPointerEnter != null) {
      widget.onPointerEnter!(event);
    }
  }

  void _handlePointerExit(PointerExitEvent event) {
    _isHovering = false;
    if (widget.onPointerExit != null) {
      widget.onPointerExit!(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = TapRegion(
      enabled: widget.active,
      onTapInside: handleTap,
      onTapOutside: widget.focusNode.hasFocus ? handleTapOutside : null,
      behavior: HitTestBehavior.opaque,
      debugLabel: 'InputFormField',
      child: MouseRegion(
        cursor: widget.mouseCursor,
        onEnter: widget.active ? _handlePointerEnter : null,
        onExit: widget.active ? _handlePointerExit : null,
        child: widget.child,
      ),
    );

    return widget.focusNode != null
        ? Focus(
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            child: result,
          )
        : result;
  }*/

  @override
  Widget build(BuildContext context) {
    Widget result = GestureDetector(
      onTap: active ? onTap : null,
      child: MouseRegion(
        cursor:
            !active ? MouseCursor.defer : (mouseCursor ?? MouseCursor.defer),
        onEnter: active ? onPointerEnter : null,
        onExit: active ? onPointerExit : null,
        child: child,
      ),
    );

    return Focus(
      canRequestFocus: false,
      autofocus: autofocus,
      focusNode: focusNode,
      child: result,
    );
  }
}
