import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_forms/ln_forms.dart';

class TextInputField extends LnFormField<String, TextEditingValue> {
  TextInputField({
    super.key,
    String? value,
    super.controller,
    super.focusNode,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.onChanged,
    super.onSaved,
    super.autofocus,
    super.validator,
    super.style,
    super.decoration,
    this.obscureText = false,
    this.canShowObscureText,
    TextInputType? keyboardType,
    this.onFieldSubmitted,
    TextInputAction? textInputAction,
    this.inputFormatters,
    this.minLines,
    this.expands = false,
    this.maxLines = 1,
    this.maxLength,
    bool? enableInteractiveSelection,
  })  : keyboardType = keyboardType ??
            (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        textInputAction = textInputAction ??
            (maxLines == 1 ? TextInputAction.next : TextInputAction.newline),
        super(
          value: controller == null ? (value ?? "") : null,
          useFocusNode: false,
          builder: (field, computedProps) {
            field as TextInputFieldState;
            final compObscure = field._obscureTextShown ? false : obscureText;

            return UnmanagedRestorationScope(
              bucket: field.bucket,
              child: TextField(
                restorationId: field.restorationId,
                controller: field.controller,
                focusNode: field.effectiveFocusNode,
                decoration: null,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                style: field.baseStyle,
                autofocus: autofocus,
                readOnly: computedProps.readOnly,
                obscuringCharacter: '•',
                obscureText: compObscure,
                onTapOutside: (_) {},
                maxLines: computedProps.readOnly
                    ? (compObscure ? 1 : null)
                    : maxLines,
                minLines: computedProps.readOnly ? null : minLines,
                expands: expands,
                maxLength: maxLength,
                canRequestFocus: field.effectiveFocusNode.canRequestFocus,
                onEditingComplete: null,
                onSubmitted: onFieldSubmitted,
                inputFormatters: inputFormatters,
                enabled: computedProps.enabled,
                enableInteractiveSelection:
                    enableInteractiveSelection ?? !compObscure,
              ),
            );
          },
        );

  final bool obscureText;
  final bool? canShowObscureText;
  final Function(String)? onFieldSubmitted;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  final TextInputType keyboardType;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final int? maxLength;

  @override
  LnFormFieldState<String, TextEditingValue> createState() {
    return TextInputFieldState();
  }
}

class TextInputFieldState extends LnFormFieldState<String, TextEditingValue> {
  bool _obscureTextShown = false;

  bool get canShowObscureText =>
      widget.obscureText && (widget.canShowObscureText ?? true);

  bool get obscureTextButtonVisibility =>
      canShowObscureText &&
      !_obscureTextShown &&
      !controller.isEmpty &&
      focused;

  @override
  TextFieldController get controller => super.controller as TextFieldController;

  @override
  TextInputField get widget => super.widget as TextInputField;

  @override
  MouseCursor get mouseCursor => MaterialStateProperty.resolveAs<MouseCursor>(
        MaterialStateMouseCursor.textable,
        <MaterialState>{
          if (!computedState.active) MaterialState.disabled,
          if (hovered) MaterialState.hovered,
          if (focused) MaterialState.focused,
          if (hasError) MaterialState.error,
        },
      );

  @override
  Widget? buildActionButton(
    BuildContext context,
    FocusNode focusNode,
  ) {
    return obscureTextButtonVisibility
        ? IconButton(
            icon: const Icon(Icons.remove_red_eye_rounded),
            onPressed: () {
              _obscureTextShown = true;
              rebuild();
            },
            focusNode: focusNode,
          )
        : super.buildActionButton(context, focusNode);
  }

  @override
  void didUpdateWidget(
      covariant LnFormField<String, TextEditingValue> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      controller
        ..didClear.addListener(_handleControllerRestore)
        ..didRestore.addListener(_handleControllerRestore);
    }
  }

  _handleControllerRestore() {
    _obscureTextShown = false;
  }

  @override
  void onFocusChanged(bool focused) {
    super.onFocusChanged(focused);

    if (!focused && _obscureTextShown) {
      _obscureTextShown = false;
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        widget.textInputAction == TextInputAction.done &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      final form = LnForm.maybeOf(context);

      if (form != null) {
        form.submit();
        return KeyEventResult.handled;
      }
    }

    return super.onKeyEvent(event);
  }

  @override
  TextFieldController createController(final String? value) {
    return TextFieldController(text: value);
  }
}

class RestorableTextFieldController
    extends RestorableChangeNotifier<TextFieldController> {
  RestorableTextFieldController({String? text})
      : this.fromValue(text == null
            ? TextEditingValue.empty
            : TextEditingValue(text: text));

  RestorableTextFieldController.fromValue(TextEditingValue? value)
      : _initialValue = value ?? TextEditingValue.empty;

  final TextEditingValue _initialValue;

  @override
  TextFieldController createDefaultValue() {
    return TextFieldController.fromValue(_initialValue);
  }

  @override
  TextFieldController fromPrimitives(Object? data) {
    return TextFieldController(text: data! as String);
  }

  @override
  Object toPrimitives() {
    return value.text;
  }
}

class TextFieldController extends TextEditingController
    implements BaseFieldController<TextEditingValue, String> {
  TextFieldController({super.text});
  TextFieldController.fromValue(TextEditingValue super.value)
      : super.fromValue();

  late TextEditingValue _savedValue = value;

  @override
  TextEditingValue get savedValue => _savedValue;

  @override
  final TextEditingValue emptyValue = TextEditingValue.empty;

  @override
  set fieldValue(String val) => value = value.copyWith(text: val);

  @override
  String get fieldValue => value.text;

  @override
  String fieldValueOf(TextEditingValue value) {
    return value.text;
  }

  @override
  TextEditingValue valueOf(String fieldValue) {
    return TextEditingValue(text: fieldValue);
  }

  @override
  void restore() {
    value = _savedValue;
  }

  @override
  void save() {
    _savedValue = value;
  }

  @override
  bool get isEmpty => value.text.isEmpty;

  @override
  bool get unsaved => value != savedValue;

  @override
  final didClear = ChangeNotifier();

  @override
  final didRestore = ChangeNotifier();

  @override
  final didSave = ChangeNotifier();
}
