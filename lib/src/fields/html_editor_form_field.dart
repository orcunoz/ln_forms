import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';
import 'package:ln_forms/src/locales/form_localizations.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import 'package:universal_platform/universal_platform.dart';

class HtmlEditorFormField extends InputFormField<String> {
  HtmlEditorFormField({
    super.key,
    super.readOnly,
    super.enabled,
    super.initialValue,
    super.focusNode,
    super.onChanged,
    super.onSaved,
    super.validator,
    super.clearable,
    super.restoreable,
    super.style,
    super.decoration,
  }) : super(
          useFocusNode: true,
          builder: (FormFieldState<String> field) {
            final theme = Theme.of(field.context);
            final state = field as _HtmlEditorFormFieldState;

            return HtmlContent(
              defaultFontSize: state.baseTextStyle.fontSize,
              data: field.value ?? "",
              linkTextColor: theme.primaryColor,
              textColor: theme.colorScheme.onBackground,
            );
          },
        );

  static bool get supported =>
      UniversalPlatform.isAndroid ||
      UniversalPlatform.isIOS ||
      UniversalPlatform.isWeb;

  @override
  InputFormFieldState<String> createState() => _HtmlEditorFormFieldState();
}

class _HtmlEditorFormFieldState extends InputFormFieldState<String>
    with FutureFormField<String> {
  late final QuillEditorController _controller;
  final editorPadding = const EdgeInsets.only(left: 10, top: 5);

  @override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: const Icon(Icons.format_align_left_rounded),
      );

  @override
  void initState() {
    super.initState();

    _controller = QuillEditorController();
  }

  @override
  Future<String?> toFuture() async {
    if (!HtmlEditorFormField.supported) {
      await InformationDialog.show(
        context: context,
        message: "HTML Editor Not Supported",
      );

      return Future.value(null);
    }

    final theme = Theme.of(context);
    _controller.setText(value ?? "");

    final mediaQuery = MediaQuery.of(context);
    final safeBottomPadding = MediaQuery.of(context).safeBottomPadding;
    final screenHeight = mediaQuery.size.height;
    final topBarHeight = mediaQuery.safePadding.top + kToolbarHeight;
    final bottomBarHeight = kToolbarHeight + safeBottomPadding.bottom;
    final iconSize = 22.0;

    final contentHeight =
        screenHeight - topBarHeight - bottomBarHeight - 2 * kToolbarHeight;
    ;
    await BackdropDialog.show(
      context: context,
      barrierColor: Colors.transparent,
      headerBackgroundColor: theme.appBarTheme.backgroundColor,
      headerForegroundColor: theme.appBarTheme.foregroundColor ??
          theme.appBarTheme.backgroundColor?.onColor,
      title: widget.decoration?.label ?? widget.decoration?.hint ?? "-",
      builder: (context) => Column(
        children: [
          ToolBar(
            toolBarColor: theme.colorScheme.surfaceVariant,
            activeIconColor: theme.primaryColor,
            iconColor: theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.all(8),
            iconSize: iconSize,
            controller: _controller,
            clipBehavior: Clip.antiAlias,
            toolBarConfig: [
              ToolBarStyle.bold,
              ToolBarStyle.italic,
              ToolBarStyle.underline,
              ToolBarStyle.blockQuote,
              ToolBarStyle.indentMinus,
              ToolBarStyle.indentAdd,
              ToolBarStyle.headerOne,
              ToolBarStyle.headerTwo,
              ToolBarStyle.color,
              ToolBarStyle.background,
              ToolBarStyle.align,
              ToolBarStyle.listOrdered,
              ToolBarStyle.listBullet,
              ToolBarStyle.size,
              ToolBarStyle.link,
              ToolBarStyle.image,
              ToolBarStyle.undo,
              ToolBarStyle.redo,
            ],
          ),
          const Divider(height: .5, thickness: .5),
          GestureDetector(
            onTap: () async {
              _controller.requestFocus();
            },
            child: QuillHtmlEditor(
              text: value,
              controller: _controller,
              isEnabled: widget.enabled,
              minHeight: contentHeight,
              textStyle: TextStyle(
                color: theme.textTheme.bodyMedium!.color,
              ),
              padding: editorPadding,
              hintText: widget.decoration?.hint,
              hintTextAlign: TextAlign.start,
              hintTextPadding: editorPadding,
              hintTextStyle: TextStyle(
                color: theme.hintColor,
              ),
            ),
          ),
          Container(
            height: bottomBarHeight,
            padding: safeBottomPadding + EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.topRight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).dividerColor, width: .5),
              ),
            ),
            child: TextButton(
              child: Text(formLocalizations.current.okButton),
              onPressed: Navigator.of(context).pop,
            ),
          ),
        ],
      ),
    );

    return (await _controller.getText()).trim();
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }
}
