import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';

class RegexResultPart {
  RegexResultPart(this.text, {this.matched = false, this.valid = true});

  final bool matched;
  final String text;
  final bool valid;
}

class SpecialTextEditingController extends TextFieldController {
  SpecialTextEditingController({
    super.text,
    required this.bracketVariables,
    required this.lessThanGreaterThanVariables,
  });

  final List<String> bracketVariables;
  final List<String> lessThanGreaterThanVariables;
  List<RegexResultPart> _parts = [];
  int errorCount = 0;

  @override
  set value(TextEditingValue newValue) {
    _parts = findParts(newValue.text);

    errorCount = _parts.where((p) => !p.valid).length;
    super.value = newValue;
  }

  List<RegexResultPart> findParts(String text) {
    final parts = <RegexResultPart>[];

    parts.addAll(findBracketsParts(text));
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (!part.matched) {
        final subParts = findLessGreaterThanParts(part.text);
        parts.removeAt(i);
        parts.insertAll(i, subParts);
        i += subParts.length - 1;
      }
    }

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (!part.matched) {
        final subParts = findUrlLinksParts(part.text);
        parts.removeAt(i);
        parts.insertAll(i, subParts);
        i += subParts.length - 1;
      }
    }

    return parts;
  }

  String insertText(String input) {
    late int newPosition;
    String currentText;
    if (selection.start == -1) {
      currentText = text + input;
      newPosition = text.length - 1;
    } else if (selection.end == -1) {
      currentText =
          "${text.substring(0, selection.start)}$input${text.substring(selection.start, text.length)}";
      newPosition = selection.start + input.length;
    } else {
      currentText =
          "${text.substring(0, selection.start)}$input${text.substring(selection.end, text.length)}";
      newPosition = selection.start + input.length;
    }

    text = currentText;
    selection = TextSelection.fromPosition(TextPosition(offset: newPosition));
    notifyListeners();
    return text;
  }

  static List<RegexResultPart> _applyRegex({
    required Iterable<RegExpMatch> Function(String input) regExpFunc,
    required String text,
    List<String>? validVariables,
  }) {
    final matches = regExpFunc(text).toList();
    var parts = <RegexResultPart>[];

    if (matches.isEmpty) {
      parts.add(RegexResultPart(text));
    } else if (matches.first.start != 0) {
      parts.add(RegexResultPart(text.substring(0, matches.first.start)));
    }

    for (var i = 0; i < matches.length; i++) {
      var highlightText = text.substring(matches[i].start, matches[i].end);
      parts.add(RegexResultPart(highlightText,
          matched: true,
          valid: validVariables == null ||
              validVariables.contains(highlightText)));
      if (i + 1 < matches.length) {
        parts.add(RegexResultPart(
            text.substring(matches[i].end, matches[i + 1].start)));
      } else if (matches[i].end < text.length) {
        parts.add(RegexResultPart(text.substring(matches[i].end, text.length)));
      }
    }

    return parts;
  }

  List<RegexResultPart> findBracketsParts(String text) => _applyRegex(
        regExpFunc: RegExpUtilities.detectBrackets,
        text: text,
        validVariables: bracketVariables,
      );

  List<RegexResultPart> findLessGreaterThanParts(String text) => _applyRegex(
        regExpFunc: RegExpUtilities.lessGreaterThanVariables,
        text: text,
        validVariables: lessThanGreaterThanVariables,
      );

  List<RegexResultPart> findUrlLinksParts(String text) => _applyRegex(
        regExpFunc: RegExpUtilities.detectLinks,
        text: text,
      );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    final nnTextStyle = style ?? const TextStyle();

    TextStyle highlightStyle =
        nnTextStyle.copyWith(color: theme.colorScheme.primary);
    TextStyle errorStyle = nnTextStyle.copyWith(
      color: theme.colorScheme.error,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.error,
      decorationStyle: TextDecorationStyle.wavy,
    );

    return TextSpan(
      style: style,
      children: _parts
          .map((e) => TextSpan(
                text: e.text,
                style:
                    e.matched ? (e.valid ? highlightStyle : errorStyle) : style,
              ))
          .toList(),
    );
  }
}
