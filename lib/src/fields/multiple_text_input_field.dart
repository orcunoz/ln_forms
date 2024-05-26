import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/editable_scope.dart';
import 'package:ln_forms/src/utilities/extensions.dart';

enum LetterCase { normal, small, capital }

class MultipleTextInputField extends LnSimpleField<List<String>> {
  MultipleTextInputField.autoSeparate({
    super.key,
    required String separator,
    String? value,
    void Function(String?)? onChanged,
    super.onSaved,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.focusNode,
    List<String> textSeparators = const [' ', ','],
    this.letterCase = LetterCase.normal,
    String? Function(String?)? validator,
    this.keyboardType = TextInputType.text,
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
          value: _autoSplit(value, separator),
          controller: null,
          useFocusNode: false,
          decoration: decoration?.apply(prefixText: const Value(null)),
          onChanged: onChanged == null
              ? null
              : (val) => onChanged(_autoJoin(val, separator)),
          validator: validator == null
              ? null
              : (val) => validator(_autoJoin(val, separator)),
          builder: (field, scopeProps) {
            field as _MultipleTextInputFieldState;
            return field._buildInside(scopeProps);
          },
          emptyValue: [],
        );

  MultipleTextInputField({
    super.key,
    super.value = const [],
    super.onChanged,
    super.onSaved,
    super.focusNode,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.validator,
    this.keyboardType = TextInputType.text,
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
          controller: null,
          decoration: decoration
              ?.copyWith(suffixIcon: const Icon(Icons.storage_rounded))
              .apply(prefixText: const Value(null)),
          builder: (field, computedState) =>
              (field as _MultipleTextInputFieldState)
                  ._buildInside(computedState),
          emptyValue: [],
        );

  final String? Function(String)? validateItem;
  final List<String> textSeparators;
  final LetterCase letterCase;
  final double minContentHeight;
  final TextInputFormatter? inputFormatter;
  final bool uniqueItems;
  final void Function()? onSubmitted;
  final String? prefixText;
  final TextInputType keyboardType;

  static List<String> _autoSplit(String? strValue, String separator) {
    return strValue?.isNotEmpty == true ? strValue!.split(separator) : [];
  }

  static String? _autoJoin(List<String>? listValue, String separator) {
    return listValue?.isNotEmpty == true ? listValue!.join(separator) : null;
  }

  @override
  LnSimpleFieldState<List<String>> createState() {
    return _MultipleTextInputFieldState();
  }
}

class _MultipleTextInputFieldState extends LnSimpleFieldState<List<String>> {
  late final _textEditingController = TextEditingController();

  final List<FocusNode> _removeIconfocusNodes = [];
  List<FocusNode> get removeIconFocusNodes => _removeIconfocusNodes
    ..grow(value.length,
        (_) => FocusNode(skipTraversal: true, canRequestFocus: false));

  static const EdgeInsets itemPadding = EdgeInsets.all(6);

  @override
  MultipleTextInputField get widget => super.widget as MultipleTextInputField;

  final Key _editableTextWidgetKey = GlobalKey(debugLabel: 'inputText');
  bool _hintActive = false;

  @override
  bool get isEmpty => value.isEmpty && _textEditingController.text.isEmpty;

  @override
  void onFocusChanged(bool hasFocus) {
    _hintActive = false;

    if (!hasFocus) {
      _addInputToValueIfValid(dontClearIfInvalid: false);
    }

    super.onFocusChanged(hasFocus);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _addInputToValueIfValid();
      return KeyEventResult.handled;
    }

    return super.onKeyEvent(event);
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

      _addInputToValueIfValid();
    }

    if (_hintActive == _textEditingController.text.isEmpty) {
      //setState(() {
      _hintActive = !_hintActive;
      //});
    }
  }

  String? _validateItem(String item) {
    if (widget.uniqueItems && value.contains(item) == true) {
      return LnFormsLocalizations.current.youHaveAlreadyAddedThis;
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

  bool _addInputToValueIfValid({bool dontClearIfInvalid = true}) {
    String input = _textEditingController.text;
    if (input.isNotEmpty) {
      if (widget.prefixText != null) {
        input = "${widget.prefixText} $input";
      }
      if (_validateItem(input) == null) {
        controller.value = (value..add(input)).toList();
        _textEditingController.clear();
      } else {
        if (!dontClearIfInvalid) {
          _textEditingController.clear();
        }
      }
    }

    return true;
  }

  Widget buildItem(int itemIndex, ComputedEditableProps computedState,
      double maxWidth, TextStyle textStyle, Color backgroundColor) {
    backgroundColor = computedState.readOnly
        ? backgroundColor.withOpacityFactor(.5)
        : backgroundColor;

    final visualDensity = VisualDensity.comfortable;
    final overflowInsets = EdgeInsets.all(8);
    final iconTapTargetSize = 42.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(width: 0.5, color: backgroundColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: itemPadding.copyWith(
                right: computedState.readOnly
                    ? null
                    : iconTapTargetSize - overflowInsets.horizontal),
            child: Text(
              value[itemIndex],
              style: textStyle,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        if (!computedState.readOnly)
          Positioned(
            right: -overflowInsets.right,
            top: -overflowInsets.top,
            bottom: -overflowInsets.bottom,
            width: iconTapTargetSize,
            child: IconButton(
              constraints: BoxConstraints.tightFor(
                width: iconTapTargetSize,
                height: iconTapTargetSize,
              ),
              visualDensity: visualDensity,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.cancel_rounded,
                size: 18.0,
                color: theme.hintColor,
              ),
              color: textStyle.color,
              onPressed: computedState.enabled
                  ? () =>
                      controller.value = (value..removeAt(itemIndex)).toList()
                  : null,
              focusNode: removeIconFocusNodes[itemIndex],
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          )
      ],
    );
  }

  Widget _buildInside(ComputedEditableProps computedState) {
    final itemBackgroundColor = theme.colorScheme.surfaceVariant;
    final style = baseStyle;
    final itemStyle = style.apply(fontSizeFactor: 0.9);

    Widget editorSide = EditableText(
      key: _editableTextWidgetKey,
      controller: _textEditingController,
      focusNode: effectiveFocusNode,
      keyboardType: widget.keyboardType,
      inputFormatters: [
        if (widget.inputFormatter != null) widget.inputFormatter!
      ],
      onSubmitted: (text) {
        if (text.isNotEmpty) {
          _addInputToValueIfValid();
          if (!effectiveFocusNode.hasFocus) effectiveFocusNode.requestFocus();
        } else {
          widget.onSubmitted?.call();
        }
      },
      onChanged: _onEditingTextChanged,
      cursorColor: theme.textSelectionTheme.cursorColor ??
          style.color ??
          itemBackgroundColor.onColor,
      backgroundCursorColor: itemBackgroundColor,
      style: style,
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
              style: style,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Transform.translate(
            offset: Offset(-itemPadding.left, 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: computedState.readOnly ? 0 : widget.minContentHeight,
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                spacing: 6,
                children: [
                  for (var i = 0; i < value.length; i++)
                    buildItem(
                      i,
                      computedState,
                      constraints.maxWidth,
                      itemStyle,
                      itemBackgroundColor,
                    ),
                ],
              ),
            ),
          ),
          if (!computedState.readOnly)
            SizedBox(
              width: effectiveFocusNode.hasFocus ? constraints.maxWidth : 0,
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

  @override
  FieldController<List<String>> createController(List<String> value) {
    return ListFieldController<String>(value);
  }
}
