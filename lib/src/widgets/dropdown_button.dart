import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ln_core/ln_core.dart';

import 'overlimit_scroll_controller.dart';

const Duration _kDropdownMenuDuration = Duration(milliseconds: 300);
const EdgeInsets _defaultMenuMargin = EdgeInsets.symmetric(vertical: 10);
const EdgeInsets _menuContentPadding = kMaterialListPadding;

class _DropdownMenuPainter extends CustomPainter {
  _DropdownMenuPainter({
    this.selectedIndex,
    required this.resize,
    required this.getSelectedItemOffset,
    required this.menuDecoration,
  })  : _painter = menuDecoration.createBoxPainter(),
        super(repaint: resize);

  final BoxDecoration menuDecoration;
  final int? selectedIndex;
  final Animation<double> resize;
  final ValueGetter<double> getSelectedItemOffset;
  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    final double selectedItemOffset = getSelectedItemOffset();
    final Tween<double> top = Tween<double>(
      begin: clampDouble(selectedItemOffset, 0.0,
          math.max(size.height - kMinInteractiveDimension, 0.0)),
      end: 0.0,
    );

    final Tween<double> bottom = Tween<double>(
      begin: clampDouble(top.begin! + kMinInteractiveDimension,
          math.min(kMinInteractiveDimension, size.height), size.height),
      end: size.height,
    );

    final Rect rect = Rect.fromLTRB(
        0.0, top.evaluate(resize), size.width, bottom.evaluate(resize));

    _painter.paint(canvas, rect.topLeft, ImageConfiguration(size: rect.size));
  }

  @override
  bool shouldRepaint(_DropdownMenuPainter oldPainter) {
    return oldPainter.menuDecoration != menuDecoration ||
        oldPainter.selectedIndex != selectedIndex ||
        oldPainter.resize != resize;
  }
}

class _DropdownMenuItemButton<T> extends StatefulWidget {
  const _DropdownMenuItemButton({
    super.key,
    required this.route,
    required this.buttonRect,
    required this.menuItem,
    required this.selected,
    required this.enableFeedback,
    required this.highlightedText,
  });

  final _DropdownRoute<T> route;
  final Rect buttonRect;
  final bool selected;
  final _MenuItem<T> menuItem;
  final bool enableFeedback;
  final String? highlightedText;

  @override
  _DropdownMenuItemButtonState<T> createState() =>
      _DropdownMenuItemButtonState<T>();
}

class _DropdownMenuItemButtonState<T>
    extends State<_DropdownMenuItemButton<T>> {
  void _handleFocusChange(bool focused) {}

  void _handleTap() {
    if (widget.route.onItemTap != null) {
      widget.route.onItemTap!(widget.menuItem.value);
    }
  }

  static const Map<ShortcutActivator, Intent> _webShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp):
        DirectionalFocusIntent(TraversalDirection.up),
  };

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation opacity;
    final double unit = 0.5 / (widget.route.items.length + 1.5);

    if (widget.selected) {
      opacity = CurvedAnimation(
          parent: widget.route.animation!, curve: const Threshold(0.0));
    } else {
      final double start =
          clampDouble(0.5 + (/*widget.itemIndex + */ 1) * unit, 0.0, 1.0);
      final double end = clampDouble(start + 1.5 * unit, 0.0, 1.0);
      opacity = CurvedAnimation(
          parent: widget.route.animation!, curve: Interval(start, end));
    }

    Widget child = FadeTransition(
      opacity: opacity,
      child: InkWell(
        autofocus: widget.selected,
        enableFeedback: widget.enableFeedback,
        onTap: _handleTap,
        onFocusChange: _handleFocusChange,
        child: widget.highlightedText?.isNotEmpty == true
            ? widget.menuItem.builder(widget.highlightedText!)
            : widget.menuItem,
      ),
    );
    if (kIsWeb) {
      child = Shortcuts(
        shortcuts: _webShortcuts,
        child: child,
      );
    }
    return child;
  }
}

class _DropdownMenu<T> extends StatefulWidget {
  const _DropdownMenu({
    super.key,
    this.itemPadding,
    required this.route,
    required this.buttonRect,
    required this.enableFeedback,
    required this.searchable,
  });

  final _DropdownRoute<T> route;
  final EdgeInsets? itemPadding;
  final Rect buttonRect;
  final bool enableFeedback;
  final bool searchable;

  @override
  _DropdownMenuState<T> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends LnState<_DropdownMenu<T>> {
  late CurvedAnimation _fadeOpacity;
  late CurvedAnimation _resize;
  Size? measuredSize;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0),
    );
    _resize = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.25, 0.9),
      reverseCurve: const Interval(0.0, 1),
    );
  }

  Widget buildListView(BuildContext context, bool searchable) {
    Widget buildInside(
        BuildContext context, SearchScopeController? searchScope) {
      var indexedItems = widget.route.items.indexed;
      if (searchScope != null) {
        indexedItems =
            searchScope.filter(indexedItems, fields: (e) => [e.$2.label]);
      }

      Widget list = ListView(
        controller: widget.route.scrollController,
        padding: _menuContentPadding,
        shrinkWrap: true,
        children: <Widget>[
          for (var (index, item) in indexedItems)
            _DropdownMenuItemButton<T>(
              route: widget.route,
              buttonRect: widget.buttonRect,
              menuItem: item,
              selected: selectedIndex == index,
              enableFeedback: widget.enableFeedback,
              highlightedText: searchScope?.value,
            ),
        ],
      );

      return searchable
          ? Column(
              children: [
                SearchTextBox(
                  fillColor: widget.route.menuDecoration.color,
                ),
                Expanded(child: list),
              ],
            )
          : list;
    }

    return searchable
        ? SearchScope.builder(builder: buildInside)
        : buildInside(context, null);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));

    Widget child = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        overscroll: true,
        physics: const ClampingScrollPhysics(),
        platform: theme.platform,
      ),
      child: Scrollbar(
        controller: widget.route.scrollController,
        thumbVisibility: true,
        child: buildListView(context, widget.searchable),
      ),
    );

    child = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: MaterialLocalizations.of(context).popupMenuLabel,
      child: child,
    );

    return FadeTransition(
      opacity: _fadeOpacity,
      child: Padding(
        padding: widget.route.menuMargin ?? EdgeInsets.zero,
        child: Align(
          alignment: Alignment.topRight,
          child: CustomPaint(
            painter: _DropdownMenuPainter(
              menuDecoration: widget.route.menuDecoration,
              selectedIndex: widget.route.selectedIndex,
              resize: _resize,
              getSelectedItemOffset: () =>
                  widget.route.getItemOffset(widget.route.selectedIndex ?? 0),
            ),
            child: Material(
              type: MaterialType.transparency,
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              borderRadius:
                  widget.route.menuDecoration.borderRadius ?? BorderRadius.zero,
              child:
                  widget.route.menuFrameBuilder?.call(context, child) ?? child,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  _DropdownMenuRouteLayout({
    required this.buttonRect,
    required this.route,
    required this.textDirection,
    required this.fixedWidth,
  });

  final Rect buttonRect;
  final _DropdownRoute<T> route;
  final TextDirection? textDirection;
  final double? fixedWidth;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxHeight = math.min(
        route.menuHeightLimit ?? double.maxFinite, route.availableHeight);

    return BoxConstraints(
      minWidth: fixedWidth ?? constraints.minWidth,
      maxWidth: fixedWidth ?? math.min(buttonRect.width, constraints.maxWidth),
      minHeight: 0,
      maxHeight: math.min(maxHeight, constraints.maxHeight),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    assert(() {
      final Rect container = Offset.zero & size;
      if (container.intersect(buttonRect) == buttonRect) {
        assert(route.menuLimits.top >= 0.0);
      }
      return true;
    }());
    assert(textDirection != null);
    final double left = switch (textDirection!) {
      TextDirection.rtl =>
        clampDouble(buttonRect.right, 0.0, size.width) - childSize.width,
      TextDirection.ltr =>
        clampDouble(buttonRect.left, 0.0, size.width - childSize.width)
    };

    return Offset(left, route.menuLimits.top);
  }

  @override
  bool shouldRelayout(_DropdownMenuRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        textDirection != oldDelegate.textDirection;
  }
}

class _MenuLimits {
  const _MenuLimits(
      this.top, this.bottom, this.scrollOffset, this.outerScrollOffset);
  final double top;
  final double bottom;
  final double scrollOffset;
  final double outerScrollOffset;

  @override
  String toString() {
    return '_MenuLimits('
        'top: $top, '
        'bottom: $bottom,'
        'scrollOffset: $scrollOffset, '
        'outerScrollOffset: $outerScrollOffset)';
  }
}

enum DropdownPosition {
  over,
  under,
}

class _DropdownRoute<T> extends PopupRoute<T> {
  _DropdownRoute({
    required this.items,
    required this.buttonRect,
    required this.selectedIndex,
    required this.capturedThemes,
    this.barrierLabel,
    this.itemHeight,
    required this.enableFeedback,
    required this.menuScreenInsets,
    required this.menuMargin,
    this.fixedWidth,
    required this.menuHeightLimit,
    required this.availableHeight,
    required this.searchable,
    this.outerScrollable,
    required this.position,
    required this.menuDecoration,
    this.menuFrameBuilder,
    this.onItemTap,
  })  : assert(position == DropdownPosition.under || menuMargin == null),
        itemHeights = List<double?>.filled(items.length, itemHeight);

  final List<_MenuItem<T>> items;
  final Rect buttonRect;
  final int? selectedIndex;
  final CapturedThemes capturedThemes;
  final double? itemHeight;
  final bool enableFeedback;
  final EdgeInsets menuScreenInsets;
  final EdgeInsets? menuMargin;
  final double? fixedWidth;
  final double? menuHeightLimit;
  final double availableHeight;
  final bool searchable;
  final DropdownPosition position;
  final BoxDecoration menuDecoration;
  final List<double?> itemHeights;
  final ScrollController scrollController = ScrollController();
  final ValueChanged<T>? onItemTap;

  final Widget Function(BuildContext context, Widget child)? menuFrameBuilder;

  final ScrollableState? outerScrollable;

  _MenuLimits? _menuLimits;
  _MenuLimits get menuLimits =>
      _menuLimits ??= getMenuLimits(buttonRect, position);

  double overflowScrollOffset = 0;

  @override
  Duration get transitionDuration => _kDropdownMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _DropdownRoutePage<T>(
      route: this,
      fixedWidth: fixedWidth,
      buttonRect: buttonRect,
      capturedThemes: capturedThemes,
      enableFeedback: enableFeedback,
      searchable: searchable,
    );
  }

  @override
  TickerFuture didPush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setScrollPositions();
    });
    return super.didPush();
  }

  @override
  void didAdd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setScrollPositions();
    });
    super.didAdd();
  }

  _setScrollPositions() {
    scrollController.jumpTo(menuLimits.scrollOffset);

    outerScrollable?.position.animateTo(
      outerScrollable!.position.pixels + menuLimits.outerScrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _dismiss() {
    final position = outerScrollable?.position;
    if (position is OverlimitScrollPositionWithSingleContext) {
      position.removeOverlimitOffset();
    }

    if (isActive) {
      navigator?.removeRoute(this);
    }
  }

  double getItemOffset(int index) {
    return (index == 0 || itemHeights.isEmpty
            ? 0
            : itemHeights
                .sublist(0, index)
                .map((e) => e ?? kMinInteractiveDimension)
                .reduce((double total, double height) => total + height)) +
        _menuContentPadding.top;
  }

  double getMenuHeight() {
    return itemHeights
            .map((e) => e ?? kMinInteractiveDimension)
            .reduce((double total, double height) => total + height) +
        _menuContentPadding.vertical;
  }

  _MenuLimits getMenuLimits(
      Rect buttonRect, DropdownPosition dropdownPosition) {
    dropdownPosition =
        selectedIndex == null ? DropdownPosition.under : dropdownPosition;

    final searchBarHeight = searchable ? kMinInteractiveDimension : 0;

    final double selectedItemOffset =
        selectedIndex == null ? 0 : getItemOffset(selectedIndex!);
    final double selectedItemHeight = selectedIndex == null
        ? kMinInteractiveDimension
        : (itemHeights[selectedIndex!] ?? kMinInteractiveDimension);
    final double listHeight = getMenuHeight() + searchBarHeight;

    final double maxHeight = math.min(
        menuHeightLimit ?? double.maxFinite,
        availableHeight -
            (dropdownPosition == DropdownPosition.under
                ? selectedItemHeight
                : 0));
    final double visibleHeight = math.min(maxHeight, listHeight);

    final double buttonTop = buttonRect.center.dy - selectedItemHeight / 2.0;
    final double buttonBottom = buttonRect.center.dy + selectedItemHeight / 2.0;

    final double topLimit = menuScreenInsets.top +
        (dropdownPosition == DropdownPosition.under ? selectedItemHeight : 0);
    final double bottomLimit = menuScreenInsets.top + availableHeight;

    double scrollOffset = selectedItemOffset -
        visibleHeight / 2 +
        selectedItemHeight +
        searchBarHeight / 2;

    double menuTop;
    if (dropdownPosition == DropdownPosition.under) {
      menuTop = buttonBottom;
    } else {
      menuTop = buttonTop - searchBarHeight - selectedItemOffset + scrollOffset;
    }
    double menuBottom = menuTop + visibleHeight;
    double outerScrollOffset = 0;

    const scrollMinLimit = 0.0;
    final scrollMaxLimit = listHeight - visibleHeight;

    if (dropdownPosition == DropdownPosition.over) {
      {
        final diff = scrollMinLimit > scrollOffset
            ? scrollOffset - scrollMinLimit
            : scrollOffset > scrollMaxLimit
                ? scrollOffset - scrollMaxLimit
                : 0;
        menuTop -= diff;
        menuBottom -= diff;
        scrollOffset -= diff;
      }

      {
        final diff = topLimit > menuTop
            ? menuTop - topLimit
            : menuBottom > bottomLimit
                ? menuBottom - bottomLimit
                : 0;

        menuTop -= diff;
        menuBottom -= diff;
        scrollOffset -= diff;
      }

      {
        final diff = scrollMinLimit > scrollOffset
            ? scrollOffset - scrollMinLimit
            : scrollOffset > scrollMaxLimit
                ? scrollOffset - scrollMaxLimit
                : 0;
        outerScrollOffset -= diff;
        scrollOffset -= diff;
      }
    } else if (dropdownPosition == DropdownPosition.under) {
      {
        final diff = scrollMinLimit > scrollOffset
            ? scrollOffset - scrollMinLimit
            : scrollOffset > scrollMaxLimit
                ? scrollOffset - scrollMaxLimit
                : 0;
        scrollOffset -= diff;
      }

      {
        final diff = topLimit > menuTop
            ? menuTop - topLimit
            : menuBottom > bottomLimit
                ? menuBottom - bottomLimit
                : 0;

        menuTop -= diff;
        menuBottom -= diff;
        outerScrollOffset += diff;
      }
    }
    /*final newVisibleHeight = menuBottom - menuTop;
    if (newVisibleHeight < visibleHeight) {
      final diff = newVisibleHeight - visibleHeight;
      visibleHeight += diff;
      outerScrollOffset -= diff;
    }*/

    /*if (selectedItemOffset < scrollOffset) {
      final diff = scrollOffset - selectedItemOffset;
      scrollOffset -= diff;
      outerScrollOffset -= diff;
    }

    final availableBottom = bottomLimit - menuBottom;

    if (outerScrollOffset > 0 && availableBottom > 0) {
      final availableDiff = math.min(availableBottom, outerScrollOffset);

      menuTop += availableDiff;
      menuBottom += availableDiff;
      outerScrollOffset -= availableDiff;
    }

    if (selectedItemOffset + selectedItemHeight >
        visibleHeight + scrollOffset) {
      final diff = selectedItemOffset + selectedItemHeight - visibleHeight;

      menuTop += diff;
      menuBottom += diff;
      scrollOffset += diff;
    }*/

    return _MenuLimits(menuTop, menuBottom, scrollOffset, outerScrollOffset);
  }
}

class _DropdownRoutePage<T> extends StatelessWidget {
  const _DropdownRoutePage({
    super.key,
    required this.route,
    required this.fixedWidth,
    required this.buttonRect,
    required this.capturedThemes,
    required this.enableFeedback,
    required this.searchable,
  });

  final _DropdownRoute<T> route;
  final double? fixedWidth;
  final Rect buttonRect;
  final CapturedThemes capturedThemes;
  final bool enableFeedback;
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = _DropdownMenu<T>(
      route: route,
      buttonRect: buttonRect,
      enableFeedback: enableFeedback,
      searchable: searchable,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _DropdownMenuRouteLayout<T>(
              buttonRect: buttonRect,
              route: route,
              textDirection: textDirection,
              fixedWidth: fixedWidth,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

class _MenuItem<T> extends SingleChildRenderObjectWidget {
  _MenuItem({
    super.key,
    required this.onLayout,
    required this.label,
    required this.value,
    required this.builder,
  }) : super(child: builder(""));

  final ValueChanged<Size> onLayout;
  final String? label;
  final T value;
  final Widget Function(String searchText) builder;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderMenuItem extends RenderProxyBox {
  _RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout(size);
  }
}

class DropdownButton<T> extends StatefulWidget {
  DropdownButton({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    this.itemAlignment = AlignmentDirectional.center,
    this.itemPadding = EdgeInsets.zero,
    this.selectedIndex,
    this.hintText,
    this.onChanged,
    this.textStyle,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.menuMaxHeight,
    this.enableFeedback,
    this.fixedWidth,
    this.searchable = false,
    this.dropdownPosition,
    this.buttonRenderBox,
  });

  final List<T> items;
  final int? selectedIndex;
  final String? hintText;
  final ValueChanged<T>? onChanged;
  final TextStyle? textStyle;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final double? menuMaxHeight;
  final bool? enableFeedback;
  final double? fixedWidth;
  final bool searchable;
  final String Function(T) itemLabelBuilder;
  final EdgeInsets itemPadding;
  final AlignmentGeometry itemAlignment;
  final DropdownPosition? dropdownPosition;
  final RenderBox? buttonRenderBox;

  static _DropdownRoute<Value<T>> _createRoute<T>({
    required BuildContext context,
    required List<T> items,
    int? selectedIndex,
    RenderBox? targetRenderBox,
    bool? searchable,
    bool? enableFeedback,
    double? fixedWidth,
    EdgeInsets? screenInsets,
    EdgeInsets? margin,
    double? maxHeight,
    BoxDecoration? decoration,
    Widget Function(BuildContext, Widget)? frameBuilder,
    DropdownPosition? position,
    TextStyle? itemTextStyle,
    String Function(T)? itemLabelBuilder,
    Widget Function(T)? itemBuilder,
    required AlignmentGeometry itemAlignment,
    required EdgeInsets itemPadding,
    required CapturedThemes capturedThemes,
    ValueChanged<T>? onItemSelect,
  }) {
    final itemRect = _itemRect(
      context: context,
      buttonRenderBox: targetRenderBox,
      itemPadding: itemPadding,
    );

    final mediaQuery = MediaQuery.of(context);
    screenInsets ??= _defaultMenuScreenInsets(mediaQuery);
    final availableHeight = mediaQuery.size.height - screenInsets.vertical;

    final theme = Theme.of(context);
    final selectedColor =
        theme.inputDecorationTheme.focusColor ?? theme.focusColor;

    late final _DropdownRoute<Value<T>> route;
    return route = _DropdownRoute<Value<T>>(
      buttonRect: itemRect,
      selectedIndex: selectedIndex,
      capturedThemes: capturedThemes,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      enableFeedback: enableFeedback ?? true,
      menuScreenInsets: screenInsets,
      menuMargin: margin,
      menuHeightLimit: maxHeight,
      menuDecoration: decoration ?? _menuDecoration(theme.popupMenuTheme),
      menuFrameBuilder: frameBuilder,
      availableHeight: availableHeight,
      searchable: searchable ?? items.length > 10,
      fixedWidth: fixedWidth ?? itemRect.width,
      outerScrollable: Scrollable.maybeOf(context),
      position: selectedIndex == null
          ? DropdownPosition.under
          : (position ?? DropdownPosition.over),
      onItemTap: (val) {
        if (onItemSelect != null) {
          onItemSelect(val.value);
        }
      },
      items: [
        for (var (index, item) in items.indexed)
          _menuItem(
            item: item,
            alignment: itemAlignment,
            padding: itemPadding,
            label: itemLabelBuilder?.call(item),
            child: itemBuilder?.call(item),
            style: itemTextStyle ?? theme.formFieldStyle,
            backgroundColor: selectedIndex == index ? selectedColor : null,
            onLayout: (Size size) => route.itemHeights[index] = size.height,
          ),
      ],
    );
  }

  static BoxDecoration _menuDecoration(PopupMenuThemeData popupTheme) {
    return BoxDecoration(
      color: popupTheme.color,
      border: Border.fromBorderSide(
          popupTheme.shape?.borderSide ?? BorderSide.none),
      borderRadius: popupTheme.shape?.borderRadius,
      boxShadow: Shadows.of(popupTheme.elevation ?? 2),
    );
  }

  static Rect _itemRect({
    required BuildContext context,
    required RenderBox? buttonRenderBox,
    required EdgeInsets itemPadding,
  }) {
    final renderBox =
        buttonRenderBox ?? context.findRenderObject()! as RenderBox;
    final ancestor =
        Navigator.of(context, rootNavigator: true).context.findRenderObject();
    final insets = buttonRenderBox == null ? itemPadding : EdgeInsets.zero;

    return renderBox.localToGlobal(Offset(-insets.left, 0),
            ancestor: ancestor) &
        Size(renderBox.size.width + insets.left + insets.right,
            renderBox.size.height);
  }

  static EdgeInsets _defaultMenuScreenInsets(MediaQueryData mediaQuery) {
    return _defaultMenuMargin + mediaQuery.safeBottomPadding;
  }

  static Widget Function(String) _itemBuilder<T>({
    required AlignmentGeometry alignment,
    required EdgeInsets padding,
    String? label,
    Widget? child,
    required Color? backgroundColor,
    required TextStyle style,
  }) =>
      (highlightedText) {
        assert(child != null || label != null);
        Widget result = Align(
          alignment: alignment,
          child: Padding(
            padding: padding,
            child: child ??
                HighlightedText(
                  label!,
                  highlightedText: highlightedText,
                  style: style,
                ),
          ),
        );

        return backgroundColor == null
            ? result
            : ColoredBox(
                color: backgroundColor,
                child: result,
              );
      };

  static _MenuItem<Value<T>> _menuItem<T>({
    required T item,
    required void Function(Size) onLayout,
    required AlignmentGeometry alignment,
    required EdgeInsets padding,
    String? label,
    Widget? child,
    required TextStyle style,
    required Color? backgroundColor,
  }) {
    return _MenuItem<Value<T>>(
      value: Value<T>(item),
      label: label,
      onLayout: onLayout,
      builder: _itemBuilder(
        alignment: alignment,
        padding: padding,
        label: label,
        child: child,
        style: style,
        backgroundColor: backgroundColor,
      ),
    );
  }

  static Future<Value<T>?> showMenu<T>({
    required BuildContext context,
    required List<T> items,
    int? selectedIndex,
    ValueChanged<T>? onChange,
    bool popOnSelect = true,
    double? menuMaxHeight,
    bool? enableFeedback,
    double? fixedWidth,
    bool? searchable,
    TextStyle? itemStyle,
    AlignmentGeometry itemAlignment = Alignment.centerLeft,
    EdgeInsets itemPadding = const EdgeInsets.all(12),
    String Function(T)? itemLabelBuilder,
    Widget Function(T)? itemBuilder,
    RenderBox? buttonRenderBox,
    EdgeInsets? menuScreenInsets,
    EdgeInsets? menuMargin,
    BoxDecoration? menuDecoration,
    Widget Function(BuildContext, Widget)? menuFrameBuilder,
  }) {
    if (items.isEmpty) Future.value(null);

    final navigator = Navigator.of(context, rootNavigator: true);
    _DropdownRoute<Value<T>>? dropdownRoute = _createRoute(
      context: context,
      selectedIndex: selectedIndex,
      items: items,
      itemPadding: itemPadding,
      itemAlignment: itemAlignment,
      itemLabelBuilder: itemLabelBuilder,
      itemBuilder: itemBuilder,
      targetRenderBox: buttonRenderBox,
      screenInsets: menuScreenInsets,
      margin: menuMargin,
      maxHeight: menuMaxHeight,
      decoration: menuDecoration,
      enableFeedback: enableFeedback,
      position: DropdownPosition.under,
      searchable: searchable,
      fixedWidth: fixedWidth,
      itemTextStyle: itemStyle,
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      frameBuilder: menuFrameBuilder,
      onItemSelect: (val) {
        if (popOnSelect) {
          navigator.pop(Value(val));
        }
        if (onChange != null) {
          onChange(val);
        }
      },
    );

    return navigator.push(dropdownRoute).whenComplete(dropdownRoute._dismiss);
  }

  @override
  State<DropdownButton<T>> createState() => DropdownButtonState<T>();
}

class DropdownButtonState<T> extends State<DropdownButton<T>>
    with WidgetsBindingObserver {
  _DropdownRoute<Value<T>>? _dropdownRoute;
  Orientation? _lastOrientation;

  FocusNode? _internalNode;
  FocusNode? get focusNode => widget.focusNode ?? _internalNode;

  bool _hasPrimaryFocus = false;
  late Map<Type, Action<Intent>> _actionMap;

  // Only used if needed to create _internalNode.
  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) => showMenu(),
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) => showMenu(),
      ),
    };
    focusNode!.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    focusNode!.removeListener(_handleFocusChanged);
    _internalNode?.dispose();
    super.dispose();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
    _lastOrientation = null;
  }

  void _handleFocusChanged() {
    if (_hasPrimaryFocus != focusNode!.hasPrimaryFocus) {
      setState(() {
        _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
      });
    }
  }

  @override
  void didUpdateWidget(DropdownButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      if (widget.focusNode == null) {
        _internalNode ??= _createFocusNode()..addListener(_handleFocusChanged);
      }
      _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
      focusNode!.addListener(_handleFocusChanged);
    }
  }

  Future<Value<T>?> showMenu() {
    if (widget.items.isEmpty) return Future.value(null);

    final navigator = Navigator.of(context, rootNavigator: true);
    _dropdownRoute = DropdownButton._createRoute(
      context: context,
      items: widget.items,
      selectedIndex: widget.selectedIndex,
      itemLabelBuilder: widget.itemLabelBuilder,
      itemPadding: widget.itemPadding,
      itemAlignment: widget.itemAlignment,
      targetRenderBox: widget.buttonRenderBox,
      maxHeight: widget.menuMaxHeight,
      enableFeedback: widget.enableFeedback,
      fixedWidth: widget.fixedWidth,
      position: widget.selectedIndex == null
          ? DropdownPosition.under
          : (widget.dropdownPosition ?? DropdownPosition.over),
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      itemTextStyle: widget.textStyle,
      searchable: widget.searchable,
      onItemSelect: (val) {
        navigator.pop(Value(val));
        if (widget.onChanged != null) {
          widget.onChanged!(val);
        }
      },
    );

    return navigator.push(_dropdownRoute!)..whenComplete(_removeDropdownRoute);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    _lastOrientation ??= mediaQuery.orientation;
    if (mediaQuery.orientation != _lastOrientation) {
      _removeDropdownRoute();
      _lastOrientation = mediaQuery.orientation;
    }

    final selectedItemLabel = widget.selectedIndex == null
        ? " "
        : widget.itemLabelBuilder(widget.items[widget.selectedIndex!]);

    return Semantics(
      button: true,
      child: Actions(
        actions: _actionMap,
        child: InkWell(
          mouseCursor: MouseCursor.defer,
          onTap: showMenu,
          canRequestFocus: widget.enabled && widget.items.isNotEmpty,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          enableFeedback: widget.enableFeedback,
          child: Text(
            selectedItemLabel,
            style: widget.textStyle ?? theme.formFieldStyle,
          ),
        ),
      ),
    );
  }
}
