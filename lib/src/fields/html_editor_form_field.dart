import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';
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
    super.validate,
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
    await BackdropDialog.show(
      context: context,
      barrierColor: Colors.transparent,
      title: widget.decoration?.label ?? widget.decoration?.hint ?? "-",
      headerBackgroundColor: theme.primaryColor,
      headerBorderRadius: BorderRadius.zero,
      body: Column(
        children: [
          ToolBar(
            toolBarColor: theme.colorScheme.surfaceVariant,
            activeIconColor: theme.primaryColor,
            iconColor: theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.all(8),
            iconSize: 20,
            controller: _controller,
            clipBehavior: Clip.antiAlias,
          ),
          const Divider(height: .5),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return QuillHtmlEditor(
                text: value,
                controller: _controller,
                isEnabled: widget.enabled,
                minHeight: constraints.maxHeight,
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
              );
            }),
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
