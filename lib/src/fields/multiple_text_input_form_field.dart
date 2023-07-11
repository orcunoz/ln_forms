import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';

enum LetterCase { normal, small, capital }

class MultipleTextInputFormField extends InputFormField<List<String>> {
  final String? Function(String)? validateItem;
  final List<String> textSeparators;
  final LetterCase letterCase;
  final double minContentHeight;
  final TextInputFormatter? inputFormatter;
  final bool uniqueItems;
  final void Function()? onSubmitted;
  final String? prefixText;

  MultipleTextInputFormField.autoSeparate({
    super.key,
    required String separator,
    String? initialValue,
    void Function(String?)? onChanged,
    super.onSaved,
    super.readOnly,
    super.enabled,
    super.focusNode,
    super.clearable,
    super.restoreable,
    List<String> textSeparators = const [' ', ','],
    this.letterCase = LetterCase.normal,
    String? Function(String?)? validate,
    this.validateItem,
    this.minContentHeight = 0,
    this.inputFormatter,
    this.onSubmitted,
    this.uniqueItems = true,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
  })  : prefixText = decoration?.prefixText,
        textSeparators = (textSeparators.contains(separator)
            ? textSeparators
            : [separator, ...textSeparators]),
        super(
          initialValue: _autoSplit(initialValue, separator),
          useFocusNode: false,
          absorbInsideTapEvents: false,
          decoration: decoration?.apply(prefixText: const Wrapped.value(null)),
          onChanged: onChanged == null
              ? null
              : (val) {
                  onChanged(_autoJoin(val, separator));
                },
          validate: (val) => validate?.call(_autoJoin(val, separator)),
          builder: (FormFieldState<List<String>> field) =>
              (field as MultipleTextInputFormFieldState)._buildInside(),
        );

  MultipleTextInputFormField({
    super.key,
    super.initialValue = const [],
    super.onChanged,
    super.onSaved,
    super.readOnly,
    super.enabled,
    super.focusNode,
    super.clearable,
    super.restoreable,
    super.validate,
    this.validateItem,
    this.textSeparators = const [' ', ','],
    this.letterCase = LetterCase.normal,
    this.minContentHeight = 0,
    this.inputFormatter,
    this.onSubmitted,
    this.uniqueItems = true,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
  })  : prefixText = decoration?.prefixText,
        super(
          useFocusNode: false,
          absorbInsideTapEvents: false,
          decoration: decoration?.apply(prefixText: const Wrapped.value(null)),
          builder: (FormFieldState<List<String>> field) =>
              (field as MultipleTextInputFormFieldState)._buildInside(),
        );

  static List<String> _autoSplit(String? strValue, String seperator) {
    return strValue?.isNotEmpty == true ? strValue!.split(seperator) : [];
  }

  static String? _autoJoin(List<String>? listValue, String seperator) {
    return listValue?.isNotEmpty == true ? listValue!.join(seperator) : null;
  }

  @override
  MultipleTextInputFormFieldState createState() {
    return MultipleTextInputFormFieldState();
  }
}

class MultipleTextInputFormFieldState
    extends InputFormFieldState<List<String>> {
  late final TextEditingController _textEditingController =
      TextEditingController();

  final List<FocusNode> _removeIconfocusNodes = [];
  List<FocusNode> get removeIconFocusNodes {
    for (int i = _removeIconfocusNodes.length; i < value.length; i++) {
      _removeIconfocusNodes
          .add(FocusNode(skipTraversal: true, canRequestFocus: false));
    }
    return _removeIconfocusNodes;
  }

  @override
  MultipleTextInputFormField get widget =>
      super.widget as MultipleTextInputFormField;

  @override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: const Icon(Icons.storage_rounded),
      );

  final Key _editableTextWidgetKey = GlobalKey(debugLabel: 'inputText');
  bool _hintActive = false;

  @override
  bool get isEmpty => super.isEmpty && _textEditingController.text.isEmpty;

  @override
  List<String> get value => super.value ?? [];

  @override
  void handleFocusChanged(bool hasFocus) {
    _hintActive = false;

    if (!hasFocus) {
      String editingText = _textEditingController.text;
      if (editingText.isNotEmpty) {
        _textEditingController.clear();
      }
      _addItemIfValid(editingText);
    } else {
      rebuild();
    }

    super.handleFocusChanged(hasFocus);
  }

  @override
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_addItemIfValid(_textEditingController.text)) {
        _textEditingController.clear();
      }
      return KeyEventResult.handled;
    }

    return super.handleKeyEvent(event);
  }

  @override
  void handleTap() {
    super.handleTap();

    if (!effectiveFocusNode.hasFocus) {
      effectiveFocusNode.requestFocus();
    }
  }

  void _onEditingTextChanged(String editingText) {
    final separator = widget.textSeparators.cast<String?>().firstWhere(
        (element) =>
            editingText.contains(element!) && editingText.indexOf(element) != 0,
        orElse: () => null);
    if (separator != null) {
      final splits = editingText.split(separator);
      final indexer = splits.length > 1 ? splits.length - 2 : splits.length - 1;

      String item = splits.elementAt(indexer).trim();
      if (widget.letterCase == LetterCase.small) {
        item = item.toLowerCase();
      } else if (widget.letterCase == LetterCase.capital) {
        item = item.toUpperCase();
      }

      if (_addItemIfValid(item)) {
        _textEditingController.clear();
      }
    }

    if (_hintActive == _textEditingController.text.isEmpty) {
      //setState(() {
      _hintActive = !_hintActive;
      //});
    }
  }

  String? _validateItem(String item) {
    if (widget.uniqueItems && value.contains(item) == true) {
      return "Bunu daha önceden eklediniz."; // TODO: You have already added this
    }

    String? errorMessage = widget.validateItem?.call(item);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    return errorMessage;
  }

  bool _addItemIfValid(String tag) {
    if (tag.isNotEmpty && _validateItem(tag) == null) {
      didChange((value..add(tag)).toList());
      return true;
    }
    return false;
  }

  Widget buildItem(int itemIndex, double maxWidth, TextStyle itemTextStyle,
      Color itemBackgroundColor) {
    final ThemeData theme = Theme.of(context);

    final borderColor = widget.readOnly
        ? theme.dividerColor.blend(theme.colorScheme.background, 50)
        : theme.dividerColor;
    itemBackgroundColor = widget.readOnly
        ? itemBackgroundColor.blend(theme.colorScheme.background, 50)
        : itemBackgroundColor;

    const removeIconSize = 18.0;
    const removeIconPadding =
        EdgeInsets.only(top: 6, bottom: 6, left: 2, right: 6);
    const leftPadding = 6.0;
    final itemTextMaximumWidth =
        maxWidth - leftPadding - removeIconSize - removeIconPadding.horizontal;

    return Material(
      color: itemBackgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 0.5, color: borderColor),
        borderRadius: theme.inputDecorationTheme.enabledBorder?.borderRadius ??
            BorderRadius.zero,
      ),
      child: Container(
        height: removeIconSize + removeIconPadding.vertical,
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        padding: const EdgeInsets.only(left: leftPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: itemTextMaximumWidth),
              child: Text(
                value[itemIndex],
                style: itemTextStyle,
                overflow: TextOverflow.fade,
              ),
            ),
            if (widget.enabled && !widget.readOnly)
              IconButton(
                constraints: BoxConstraints.tightFor(
                  width: removeIconSize + removeIconPadding.vertical,
                  height: removeIconSize + removeIconPadding.vertical,
                ),
                visualDensity: VisualDensity.comfortable,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.cancel_rounded,
                  size: removeIconSize,
                  color: theme.hintColor,
                ),
                color: itemTextStyle.color,
                onPressed: () =>
                    didChange((value..removeAt(itemIndex)).toList()),
                focusNode: removeIconFocusNodes[itemIndex],
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
            else
              const SizedBox(width: leftPadding)
          ],
        ),
      ),
    );
  }

  Widget _buildInside() {
    final ThemeData theme = Theme.of(context);

    final itemBackgroundColor = theme.highlightColor;
    final itemTextStyle = baseTextStyle.apply(fontSizeFactor: 0.9);

    Widget editorSide = EditableText(
      key: _editableTextWidgetKey,
      controller: _textEditingController,
      focusNode: effectiveFocusNode,
      inputFormatters: [
        if (widget.inputFormatter != null) widget.inputFormatter!
      ],
      onSubmitted: (text) {
        if (text.isNotEmpty) {
          _textEditingController.clear();
          _addItemIfValid(text);
          if (!effectiveFocusNode.hasFocus) effectiveFocusNode.requestFocus();
        } else {
          widget.onSubmitted?.call();
        }
      },
      onChanged: _onEditingTextChanged,
      cursorColor: theme.textSelectionTheme.cursorColor ??
          itemTextStyle.color ??
          itemBackgroundColor.onColor,
      backgroundCursorColor: itemBackgroundColor,
      style: baseTextStyle,
    );

    if (widget.prefixText != null) {
      editorSide = Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
              widget.prefixText!,
              style: baseTextStyle,
            ),
          ),
          Expanded(child: editorSide),
        ],
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      return SpacedColumn(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              minHeight: widget.readOnly ? 0 : widget.minContentHeight,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              spacing: 4,
              children: [
                for (var i = 0; i < value.length; i++)
                  buildItem(i, constraints.maxWidth, itemTextStyle,
                      itemBackgroundColor),
              ],
            ),
          ),
          Container(
            width: effectiveFocusNode.hasFocus ? constraints.maxWidth : 0,
            height: widget.readOnly ? 0 : null,
            alignment: Alignment.bottomLeft,
            child: editorSide,
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    for (final focusNode in _removeIconfocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
