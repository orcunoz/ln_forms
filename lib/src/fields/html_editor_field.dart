import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_dialogs/ln_dialogs.dart';
import 'package:quill_html_editor/quill_html_editor.dart';

class HtmlEditorField extends LnSimpleFutureField<String> {
  HtmlEditorField({
    super.key,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.value = "",
    super.controller,
    super.focusNode,
    super.onChanged,
    super.onSaved,
    super.validator,
    super.style,
    LnDecoration? decoration = const LnDecoration(),
  }) : super(
          decoration: decoration?.copyWith(
            suffixIcon: const Icon(Icons.format_align_left_rounded),
          ),
          useFocusNode: true,
          builder: (field, computedState) {
            field as _HtmlEditorFieldState;

            return HtmlContent(
              defaultFontSize: field.baseStyle.fontSize,
              data: field.value,
              linkTextColor: field.theme.colorScheme.primary,
              textColor: field.theme.colorScheme.onSurface,
            );
          },
          emptyValue: "",
          onTrigger: _onTrigger,
        );

  static bool get supported =>
      LnPlatform.isAndroid || LnPlatform.isIOS || LnPlatform.isWeb;

  @override
  LnSimpleFutureFieldState<String> createState() => _HtmlEditorFieldState();

  static Future<String?> _onTrigger(
      LnSimpleFutureFieldState<String> state) async {
    const editorPadding = EdgeInsets.only(left: 10, top: 5);

    final controller = (state as _HtmlEditorFieldState)._controller;
    final theme = state.theme;

    final field = state.widget as HtmlEditorField;

    if (!HtmlEditorField.supported) {
      final localizations = LnFormsLocalizations.of(state.context);
      await InformationDialog.show(
        context: state.context,
        title: localizations.htmlEditorNotSupported,
        message: localizations.htmlEditorNotSupportedWarning,
      );

      return Future.value(null);
    }

    controller.setText(state.value);

    final screenHeight = state.mediaQuery.size.height;
    final topBarHeight = state.mediaQuery.safePadding.top + kToolbarHeight;
    final bottomBarHeight = kToolbarHeight;
    final iconSize = 22.0;

    final contentHeight =
        screenHeight - topBarHeight - bottomBarHeight - 2 * kToolbarHeight;

    await BottomSheetDialog.show(
      context: state.context,
      barrierColor: Colors.transparent,
      headerBackgroundColor: theme.appBarTheme.backgroundColor,
      headerForegroundColor: theme.appBarTheme.foregroundColor ??
          theme.appBarTheme.backgroundColor?.onColor,
      title: field.decoration?.label ?? field.decoration?.hint ?? "-",
      builder: (context) => Column(
        children: [
          ToolBar(
            toolBarColor: theme.colorScheme.surface,
            activeIconColor: theme.colorScheme.primary,
            iconColor: theme.colorScheme.onSurfaceVariant,
            padding: const EdgeInsets.all(8),
            iconSize: iconSize,
            controller: controller,
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
              controller.requestFocus();
            },
            child: QuillHtmlEditor(
              text: state.value,
              controller: controller,
              isEnabled: state.computedState.enabled,
              minHeight: contentHeight,
              textStyle: TextStyle(color: theme.textTheme.bodyMedium!.color),
              padding: editorPadding,
              hintText: field.decoration?.hint,
              hintTextAlign: TextAlign.start,
              hintTextPadding: editorPadding,
              hintTextStyle: TextStyle(color: theme.hintColor),
            ),
          ),
          Container(
            height: bottomBarHeight,
            padding: EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.topRight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: state.dividerBorders.top,
            ),
            child: TextButton(
              child: Text(LnFormsLocalizations.current.okButton),
              onPressed: Navigator.of(context).pop,
            ),
          ),
        ],
      ),
    );

    return (await controller.getText()).trim();
  }
}

class _HtmlEditorFieldState extends LnSimpleFutureFieldState<String> {
  late final QuillEditorController _controller;

  @override
  void initState() {
    super.initState();

    _controller = QuillEditorController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  FieldController<String> createController(String value) {
    return HtmlEditorFieldController(value);
  }
}

class HtmlEditorFieldController extends QuillEditorController
    with ChangeNotifier
    implements FieldController<String> {
  HtmlEditorFieldController(String value)
      : _value = value,
        _savedValue = value {
    onTextChanged((data) => value = data);
  }

  String _savedValue;
  @override
  String get savedValue => _savedValue;

  @override
  String get emptyValue => "";

  String _value;
  @override
  String get value => _value;
  @override
  set value(String val) {
    if (_value != val) {
      _value = val;
      notifyListeners();
    }
  }

  @override
  void restore() {
    value = savedValue;
  }

  @override
  void save() {
    _savedValue = value;
  }

  @override
  late String fieldValue = fieldValueOf(value);

  @override
  String fieldValueOf(String value) => value;

  @override
  String valueOf(String fieldValue) => fieldValue;

  @override
  bool get isEmpty => value == emptyValue;

  @override
  bool get unsaved => value != _savedValue;

  @override
  final ChangeNotifier didClear = ChangeNotifier();

  @override
  final ChangeNotifier didRestore = ChangeNotifier();

  @override
  final ChangeNotifier didSave = ChangeNotifier();
}
