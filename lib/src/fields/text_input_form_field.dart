import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ln_forms/ln_forms.dart';

class TextInputFormField extends InputFormField<String> {
  final bool obscureText;
  final bool? userCanSeeObscureText;
  final Function(String)? onFieldSubmitted;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  final TextInputType keyboardType;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final int? maxLength;

  final TextEditingController? controller;

  TextInputFormField({
    super.key,
    String? initialValue,
    super.focusNode,
    super.readOnly = false,
    super.enabled,
    super.onChanged,
    super.onSaved,
    super.autofocus,
    super.validate,
    super.clearable,
    super.restoreable,
    super.style,
    this.obscureText = false,
    this.userCanSeeObscureText,
    super.decoration,
    this.controller,
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
        assert(initialValue == null || controller == null),
        super(
          useFocusNode: false,
          initialValue:
              controller != null ? controller.text : (initialValue ?? ''),
          builder: (InputFormFieldState<String> field) {
            final state = field as TextInputFormFieldState;
            final compObscureContent =
                state._obscureContentIsVisible ? false : obscureText;

            return UnmanagedRestorationScope(
              bucket: state.bucket,
              child: TextField(
                restorationId: state.restorationId,
                controller: state._effectiveController,
                focusNode: state.effectiveFocusNode,
                decoration: null,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                style: state.baseTextStyle,
                autofocus: autofocus,
                readOnly: readOnly,
                obscuringCharacter: '•',
                obscureText: compObscureContent,
                maxLines: readOnly ? (compObscureContent ? 1 : null) : maxLines,
                minLines: readOnly ? null : minLines,
                expands: expands,
                maxLength: maxLength,
                onTap: state.isActive ? state.handleTap : null,
                onTapOutside: (_) =>
                    state.isFocused ? state.handleTapOutside() : null,
                onEditingComplete: null,
                onSubmitted: onFieldSubmitted,
                inputFormatters: inputFormatters,
                enabled: state.isActive,
                mouseCursor: MouseCursor.defer,
                /*enableInteractiveSelection:
            enableInteractiveSelection ?? (!widget.obscureText || !widget.readOnly),*/
              ),
            );
          },
        );

  @override
  TextInputFormFieldState createState() {
    return TextInputFormFieldState();
  }
}

class TextInputFormFieldState extends InputFormFieldState<String> {
  bool _obscureContentIsVisible = false;

  RestorableTextEditingController? _controller;
  TextEditingController get _effectiveController =>
      widget.controller ?? _controller!.value;

  bool get userCanSeeObscureContent =>
      widget.obscureText && (widget.userCanSeeObscureText ?? true);

  bool get obscureContentButtonIsVisible =>
      userCanSeeObscureContent &&
      !_obscureContentIsVisible &&
      !isEmpty &&
      isFocused;

  @override
  TextInputFormField get widget => super.widget as TextInputFormField;

  /*@override
  LnDecoration get baseDecoration => super.baseDecoration.copyWith(
        suffixIcon: const Icon(Icons.keyboard),
      );*/

  @override
  Widget? get editingActionButton => obscureContentButtonIsVisible
      ? IconButton(
          icon: const Icon(Icons.remove_red_eye_rounded),
          onPressed: () {
            _obscureContentIsVisible = true;
            rebuild();
          },
          focusNode: editingActionButtonFocusNode,
        )
      : super.editingActionButton;

  @override
  MouseCursor get effectiveMouseCursor =>
      MaterialStateProperty.resolveAs<MouseCursor>(
        MaterialStateMouseCursor.textable,
        <MaterialState>{
          if (!isActive) MaterialState.disabled,
          if (isHovering) MaterialState.hovered,
          if (isFocused) MaterialState.focused,
          if (hasError) MaterialState.error,
        },
      );

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    if (_controller != null) {
      _registerController();
    }
    // Make sure to update the internal [FormFieldState] value to sync up with
    // text editing controller value.
    setValue(_effectiveController.text);
  }

  void _registerController() {
    assert(_controller != null);
    registerForRestoration(_controller!, 'controller');
  }

  void _createInternalController([TextEditingValue? value]) {
    assert(_controller == null);
    _controller = value == null
        ? RestorableTextEditingController()
        : RestorableTextEditingController.fromValue(value);
    if (!restorePending) {
      _registerController();
    }
    _controller!.addListener(_handleControllerChanged);
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _createInternalController(widget.initialValue != null
          ? TextEditingValue(text: widget.initialValue!)
          : null);
    } else {
      widget.controller!.addListener(_handleControllerChanged);
    }
  }

  @override
  void didUpdateWidget(TextInputFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && widget.controller == null) {
        _createInternalController(oldWidget.controller!.value);
        _controller!.addListener(_handleControllerChanged);
      }

      if (widget.controller != null) {
        if (oldWidget.controller == null) {
          unregisterFromRestoration(_controller!);
          _controller!.dispose();
          _controller = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    _controller?.dispose();
    //focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _handleControllerChanged() {
    didChange(_effectiveController.text);
  }

  @override
  void handleFocusChanged(bool hasFocus) {
    super.handleFocusChanged(hasFocus);
    if (!hasFocus) {
      _obscureContentIsVisible = false;
    }
  }

  @override
  void handleTap() {
    super.handleTap();

    effectiveFocusNode.requestFocus();
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_effectiveController.text != value) {
      _effectiveController.text = value ?? '';
    }
  }

  @override
  void reset() {
    _effectiveController.text = widget.initialValue ?? '';
    _obscureContentIsVisible = false;
    super.reset();
  }
}
