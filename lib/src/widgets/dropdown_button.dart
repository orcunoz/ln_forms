// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';

const Duration _kDropdownMenuDuration = Duration(milliseconds: 300);
const EdgeInsets _defaultMenuMargin = EdgeInsets.symmetric(vertical: 10);
const EdgeInsets _menuContentPadding = kMaterialListPadding;

class _DropdownMenuPainter extends CustomPainter {
  _DropdownMenuPainter({
    this.color,
    this.elevation,
    this.selectedIndex,
    this.borderRadius,
    required this.resize,
    required this.getSelectedItemOffset,
  })  : _painter = BoxDecoration(
          color: color,
          borderRadius:
              borderRadius ?? const BorderRadius.all(Radius.circular(2.0)),
          boxShadow: kElevationToShadow[elevation],
        ).createBoxPainter(),
        super(repaint: resize);

  final Color? color;
  final int? elevation;
  final int? selectedIndex;
  final BorderRadius? borderRadius;
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
    return oldPainter.color != color ||
        oldPainter.elevation != elevation ||
        oldPainter.selectedIndex != selectedIndex ||
        oldPainter.borderRadius != borderRadius ||
        oldPainter.resize != resize;
  }
}

class _DropdownMenuItemButton<T> extends StatefulWidget {
  const _DropdownMenuItemButton({
    super.key,
    required this.route,
    required this.buttonRect,
    required this.itemIndex,
    required this.enableFeedback,
    required this.searchText,
  });

  final _DropdownRoute<T> route;
  final Rect buttonRect;
  final int itemIndex;
  final bool enableFeedback;
  final String searchText;

  @override
  _DropdownMenuItemButtonState<T> createState() =>
      _DropdownMenuItemButtonState<T>();
}

class _DropdownMenuItemButtonState<T>
    extends State<_DropdownMenuItemButton<T>> {
  void _handleFocusChange(bool focused) {}

  void _handleOnTap() {
    Navigator.pop(
      context,
      widget.route.items[widget.itemIndex].value,
    );
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
    if (widget.itemIndex == widget.route.selectedIndex) {
      opacity = CurvedAnimation(
          parent: widget.route.animation!, curve: const Threshold(0.0));
    } else {
      final double start =
          clampDouble(0.5 + (widget.itemIndex + 1) * unit, 0.0, 1.0);
      final double end = clampDouble(start + 1.5 * unit, 0.0, 1.0);
      opacity = CurvedAnimation(
          parent: widget.route.animation!, curve: Interval(start, end));
    }
    Widget child = widget.searchText.isEmpty
        ? widget.route.items[widget.itemIndex]
        : widget.route.items[widget.itemIndex].builder(widget.searchText);

    final focusedIndex = widget.route.selectedIndex ?? 0;

    child = InkWell(
      autofocus: widget.itemIndex == focusedIndex,
      enableFeedback: widget.enableFeedback,
      onTap: _handleOnTap,
      onFocusChange: _handleFocusChange,
      child: child,
    );

    child = FadeTransition(opacity: opacity, child: child);
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
    this.borderRadius,
    required this.searchable,
  });

  final _DropdownRoute<T> route;
  final EdgeInsets? itemPadding;
  final Rect buttonRect;
  final bool enableFeedback;
  final BorderRadius? borderRadius;
  final bool searchable;

  @override
  _DropdownMenuState<T> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<_DropdownMenu<T>> {
  late CurvedAnimation _fadeOpacity;
  late CurvedAnimation _resize;
  String _searchText = "";
  Size? measuredSize;

  TextEditingController? _searchTextController;

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

    if (widget.searchable) {
      _searchTextController = TextEditingController()
        ..addListener(_handleTextListener);
    }
  }

  _handleTextListener() {
    setState(() {
      _searchText = _searchTextController?.text.trim() ?? "";
      if (_searchText == "") {
        widget.route.scrollController
            .jumpTo(widget.route.menuLimits.scrollOffset);
      }
    });
  }

  @override
  void dispose() {
    _searchTextController
      ?..removeListener(_handleTextListener)
      ..dispose();
    super.dispose();
  }

  Color get _backgroundColor =>
      Theme.of(context).popupMenuTheme.color ??
      Theme.of(context).colorScheme.background;

  BorderRadius get _borderRadius =>
      Theme.of(context).inputDecorationTheme.borderRadius ??
      BorderRadius.circular(2);

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final titleForegroundColor = theme.colorScheme.onBackground;
    final style = DefaultTextStyle.of(context).style;
    final textFieldBorder = UnderlineInputBorder(
      borderSide: BorderSide(width: 0.5, color: theme.dividerColor),
    );
    return TextField(
      cursorColor: titleForegroundColor,
      controller: _searchTextController,
      style: style.copyWith(
        color: titleForegroundColor,
      ),
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        contentPadding: widget.itemPadding,
        prefixIcon: _searchTextController!.text.isEmpty
            ? Icon(
                Icons.search_rounded,
                color: titleForegroundColor,
              )
            : IconButton(
                onPressed: () => setState(() {
                  _searchTextController!.clear();
                }),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        hintText: "${MaterialLocalizations.of(context).searchFieldLabel}...",
        hintStyle: style.copyWith(
          color: titleForegroundColor.withOpacity(0.7),
        ),
        border: textFieldBorder,
        enabledBorder: textFieldBorder,
        focusedBorder: textFieldBorder,
        filled: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final theme = Theme.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    final searchText = _searchText.toLowerCase();

    final List<Widget> children = <Widget>[
      for (int itemIndex = 0;
          itemIndex < widget.route.items.length;
          ++itemIndex)
        if (widget.route.items[itemIndex].label
            .toLowerCase()
            .contains(searchText))
          _DropdownMenuItemButton<T>(
            route: widget.route,
            buttonRect: widget.buttonRect,
            itemIndex: itemIndex,
            enableFeedback: widget.enableFeedback,
            searchText: _searchText,
          ),
    ];

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
        child: ListView(
          controller: widget.route.scrollController,
          padding: _menuContentPadding,
          shrinkWrap: true,
          children: children,
        ),
      ),
    );

    if (widget.searchable) {
      child = Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: kMinInteractiveDimension,
            child: Material(child: _buildSearchBar(context)),
          ),
          Flexible(child: child),
        ],
      );
    }

    return FadeTransition(
      opacity: _fadeOpacity,
      child: Container(
        alignment: Alignment.topLeft,
        child: CustomPaint(
          painter: _DropdownMenuPainter(
            color: _backgroundColor,
            elevation: widget.route.elevation,
            selectedIndex: widget.route.selectedIndex,
            resize: _resize,
            borderRadius: _borderRadius,
            getSelectedItemOffset: () =>
                widget.route.getItemOffset(widget.route.selectedIndex ?? 0),
          ),
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: _borderRadius,
            child: Material(
              color: Colors.transparent,
              type: MaterialType.transparency,
              textStyle: widget.route.style,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              shape: RoundedRectangleBorder(
                borderRadius: _borderRadius,
                side: theme.brightness == Brightness.light
                    ? BorderSide.none
                    : BorderSide(
                        width: .5,
                        color: theme.dividerColor,
                      ),
              ),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: localizations.popupMenuLabel,
                child: child,
              ),
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
    final double left;
    switch (textDirection!) {
      case TextDirection.rtl:
        left = clampDouble(buttonRect.right, 0.0, size.width) - childSize.width;
        break;
      case TextDirection.ltr:
        left = clampDouble(buttonRect.left, 0.0, size.width - childSize.width);
        break;
    }

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
    return '_MenuLimits(top: $top, bottom: $bottom, scrollOffset: $scrollOffset, outerScrollOffset: $outerScrollOffset)';
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
    this.elevation = 8,
    required this.capturedThemes,
    required this.style,
    this.barrierLabel,
    this.itemHeight,
    required this.enableFeedback,
    this.borderRadius,
    required this.menuMargin,
    this.fixedWidth,
    required this.menuHeightLimit,
    required this.availableHeight,
    required this.searchable,
    this.lnFormState,
    required this.dropdownPosition,
  }) : itemHeights = List<double?>.filled(items.length, itemHeight);

  final List<_MenuItem<T>> items;
  final Rect buttonRect;
  final int? selectedIndex;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle style;
  final double? itemHeight;
  final bool enableFeedback;
  final BorderRadius? borderRadius;
  final EdgeInsets menuMargin;
  final double? fixedWidth;
  final double? menuHeightLimit;
  final double availableHeight;
  final bool searchable;
  final LnFormFocusTarget? lnFormState;
  final DropdownPosition dropdownPosition;

  final List<double?> itemHeights;
  final ScrollController scrollController = ScrollController();

  _MenuLimits? _menuLimits;
  _MenuLimits get menuLimits =>
      _menuLimits ??= getMenuLimits(buttonRect, dropdownPosition);

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
      elevation: elevation,
      capturedThemes: capturedThemes,
      style: style,
      enableFeedback: enableFeedback,
      borderRadius: borderRadius,
      searchable: searchable,
    );
  }

  @override
  TickerFuture didPush() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOverflowScroll();
      _setScrollPositions();
    });
    return super.didPush();
  }

  @override
  void didAdd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setOverflowScroll();
      _setScrollPositions();
    });
    super.didAdd();
  }

  _setOverflowScroll() {
    final controller = lnFormState?.scrollController;
    overflowScrollOffset = 0;

    if (controller?.hasClients == true) {
      final maxScroll = controller!.position.maxScrollExtent;
      double newOuterScrollOffset =
          controller.offset + menuLimits.outerScrollOffset;
      overflowScrollOffset = 0;

      if (newOuterScrollOffset > maxScroll) {
        overflowScrollOffset = newOuterScrollOffset - maxScroll;
        newOuterScrollOffset = maxScroll;
      }

      if (newOuterScrollOffset < 0) {
        overflowScrollOffset = newOuterScrollOffset;
        newOuterScrollOffset = 0;
      }
    }

    lnFormState?.setTranslationY(-overflowScrollOffset);
  }

  _setScrollPositions() {
    final primaryController = lnFormState?.scrollController;

    if (primaryController != null) {
      double newOuterScrollOffset =
          primaryController.offset + menuLimits.outerScrollOffset;
      newOuterScrollOffset = math.min(
          newOuterScrollOffset, primaryController.position.maxScrollExtent);
      newOuterScrollOffset = math.max(newOuterScrollOffset, 0);

      primaryController.animateTo(
        newOuterScrollOffset,
        duration: const Duration(milliseconds: 100),
        curve: Curves.bounceInOut,
      );
    }

    scrollController.jumpTo(menuLimits.scrollOffset);
  }

  void _dismiss() {
    if (overflowScrollOffset != 0) {
      lnFormState?.setTranslationY(0);
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

    final double topLimit = menuMargin.top +
        (dropdownPosition == DropdownPosition.under ? selectedItemHeight : 0);
    final double bottomLimit = menuMargin.top + availableHeight;

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
    this.elevation = 8,
    required this.capturedThemes,
    this.style,
    required this.enableFeedback,
    this.borderRadius,
    required this.searchable,
  });

  final _DropdownRoute<T> route;
  final double? fixedWidth;
  final Rect buttonRect;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final bool enableFeedback;
  final BorderRadius? borderRadius;
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = _DropdownMenu<T>(
      route: route,
      buttonRect: buttonRect,
      enableFeedback: enableFeedback,
      borderRadius: borderRadius,
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
  final String label;
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
    this.value,
    this.hintText,
    this.onChanged,
    this.onTap,
    this.elevation = 2,
    this.style,
    this.isExpanded = false,
    this.enabled = true,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.center,
    this.borderRadius,
    this.fixedWidth,
    this.searchable = false,
    this.itemPadding = EdgeInsets.zero,
    required this.focusedBorder,
    this.dropdownPosition,
    this.buttonRenderBox,
  }) : assert(items == null ||
            items.isEmpty ||
            value == null ||
            items.where((T item) {
                  return item == value;
                }).length ==
                1);

  final List<T>? items;
  final T? value;
  final String? hintText;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final String Function(T?) itemLabelBuilder;
  final int elevation;
  final TextStyle? style;
  final bool isExpanded;
  final bool enabled;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final double? fixedWidth;
  final bool searchable;
  final EdgeInsets itemPadding;
  final InputBorder? focusedBorder;
  final DropdownPosition? dropdownPosition;
  final RenderBox? buttonRenderBox;

  @override
  State<DropdownButton<T>> createState() => DropdownButtonState<T>();
}

class DropdownButtonState<T> extends State<DropdownButton<T>>
    with WidgetsBindingObserver {
  _DropdownRoute<(T?,)?>? _dropdownRoute;
  Orientation? _lastOrientation;

  FocusNode? _internalNode;
  FocusNode? get focusNode => widget.focusNode ?? _internalNode;

  bool _hasPrimaryFocus = false;
  late Map<Type, Action<Intent>> _actionMap;

  EdgeInsets get effectiveItemPadding {
    var radio = effectiveDropdownPosition == DropdownPosition.under ? 1 : 0.5;
    return widget.itemPadding.copyWith(
      left: widget.itemPadding.left * radio,
      right: widget.itemPadding.right * radio,
    );
  }

  bool get _enabled =>
      widget.enabled &&
      widget.items != null &&
      widget.items!.isNotEmpty &&
      widget.onChanged != null;

  //double? _currentHeight;

  // Only used if needed to create _internalNode.
  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  int? get selectedIndex {
    if (widget.value == null || widget.items == null) return null;

    var index = widget.items!.indexOf(widget.value as T);
    return index == -1 ? null : index;
  }

  TextStyle? get _effectiveTextStyle =>
      widget.style ?? Theme.of(context).defaultFormFieldStyle;

  DropdownPosition get effectiveDropdownPosition =>
      widget.dropdownPosition == DropdownPosition.under || selectedIndex == null
          ? DropdownPosition.under
          : DropdownPosition.over;

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

  Rect get itemRect {
    final renderBox =
        widget.buttonRenderBox ?? context.findRenderObject()! as RenderBox;
    final insets =
        widget.buttonRenderBox == null ? effectiveItemPadding : EdgeInsets.zero;
    final ancestor =
        Navigator.of(context, rootNavigator: true).context.findRenderObject();
    return _calculateRect(renderBox, insets, ancestor);
  }

  Rect _calculateRect(
      RenderBox itemBox, EdgeInsets insets, RenderObject? ancestor) {
    return itemBox.localToGlobal(
            Offset(-insets.left, widget.focusedBorder?.borderSide.width ?? 0),
            ancestor: ancestor) &
        Size(itemBox.size.width + insets.left + insets.right,
            itemBox.size.height);
  }

  Future<T?> showMenu() async {
    if (!_enabled) Future<T?>.value(null);
    final items = widget.items ?? [];

    final theme = Theme.of(context);
    final highlightColor = widget.focusColor ??
        (theme.inputDecorationTheme.filled
            ? theme.inputDecorationTheme.fillColor
            : theme.highlightColor) ??
        theme.colorScheme.onBackground.withOpacity(0.1);

    _MenuItem<(T,)?> buildMenuItem(int itemIndex) {
      final item = items[itemIndex];
      final label = widget.itemLabelBuilder(item);

      return _MenuItem<(T,)?>(
        builder: (searchText) {
          final isSelected = item == widget.value;
          final borderWidth = widget.focusedBorder?.borderSide.width ?? 0;
          final padding = isSelected
              ? effectiveItemPadding -
                  EdgeInsets.only(
                    top: borderWidth * 2,
                  )
              : effectiveItemPadding;
          final decoration = isSelected
              ? BoxDecoration(
                  color: highlightColor,
                  border: Border.symmetric(
                    horizontal:
                        widget.focusedBorder?.borderSide ?? BorderSide.none,
                  ),
                )
              : null;

          return Container(
            padding: padding,
            alignment: widget.alignment,
            decoration: decoration,
            constraints:
                const BoxConstraints(minHeight: kMinInteractiveDimension),
            child: HighlightedText(
              label,
              highlightedText: searchText,
              style: _effectiveTextStyle,
            ),
          );
        },
        label: label,
        value: (item,),
        onLayout: (Size size) =>
            _dropdownRoute?.itemHeights[itemIndex] = size.height,
      );
    }

    final List<_MenuItem<(T,)?>> menuItems = [
      for (var i = 0; i < items.length; i++) buildMenuItem(i)
    ];

    assert(_dropdownRoute == null);
    final buttonRect = EdgeInsets.zero.inflateRect(itemRect);
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding.copyWith(
        bottom:
            math.max(mediaQuery.padding.bottom, mediaQuery.viewInsets.bottom));
    final menuMargin = _defaultMenuMargin +
        safePadding +
        const EdgeInsets.only(top: kToolbarHeight);

    final availableHeight = mediaQuery.size.height - menuMargin.vertical;

    final navigator = Navigator.of(context, rootNavigator: true);

    _dropdownRoute = _DropdownRoute<(T,)?>(
      items: menuItems,
      buttonRect: buttonRect,
      selectedIndex: selectedIndex,
      elevation: widget.elevation,
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      style: _effectiveTextStyle!,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      enableFeedback: widget.enableFeedback ?? true,
      borderRadius: widget.borderRadius,
      menuMargin: menuMargin,
      menuHeightLimit: widget.menuMaxHeight,
      availableHeight: availableHeight,
      fixedWidth: widget.fixedWidth ?? buttonRect.width,
      searchable: widget.searchable,
      lnFormState: LnFormFocusTarget.of(context),
      dropdownPosition: effectiveDropdownPosition,
    );

    final newValue = await navigator.push(_dropdownRoute!);

    _removeDropdownRoute();
    if (newValue != null) {
      widget.onChanged?.call(newValue.$1);
    }

    return newValue!.$1;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final mediaQuery = MediaQuery.of(context);
    _lastOrientation ??= mediaQuery.orientation;
    if (mediaQuery.orientation != _lastOrientation) {
      _removeDropdownRoute();
      _lastOrientation = mediaQuery.orientation;
    }

    Widget child;

    final T? selectedItem =
        selectedIndex != null ? widget.items![selectedIndex!] : null;

    if (selectedItem == null) {
      child = DefaultTextStyle(
        style: _effectiveTextStyle!,
        child: const Text(" "),
      );
    } else {
      child = DefaultTextStyle(
        style: _effectiveTextStyle!,
        child: Text(widget.itemLabelBuilder(selectedItem)),
      );
    }

    return Semantics(
      button: true,
      child: Actions(
        actions: _actionMap,
        child: InkWell(
          mouseCursor: MouseCursor.defer,
          onTap: showMenu,
          canRequestFocus: _enabled,
          borderRadius: widget.borderRadius,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          enableFeedback: false,
          child: child,
        ),
      ),
    );
  }
}
