part of 'form.dart';

enum _LnFormButtonType {
  enableEditing,
  submit,
  cancelEditing,
  restore,
  clear,
}

typedef OnPressed = FutureOr Function(LnFormController);

const _defaultOfType = "\$\$DEF\$\$";

class LnFormButton extends StatefulWidget {
  final String? text;
  final Widget? icon;
  final String? tooltip;
  final OnPressed? onPressed;
  final ButtonStyle? style;
  final Set<FormModes> effectiveModes;
  final bool primary;

  final _LnFormButtonType? _type;

  const LnFormButton({
    this.text,
    this.icon,
    this.tooltip,
    required this.onPressed,
    this.style,
    this.effectiveModes = const {FormModes.view, FormModes.edit},
    this.primary = true,
  }) : _type = null;

  const LnFormButton._({
    required _LnFormButtonType type,
    required this.text,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.effectiveModes,
    required this.style,
    required this.primary,
  })  : _type = type,
        assert(text != null || icon != null);

  LnFormButton.startEditing({
    String? text = _defaultOfType,
    Widget? icon = const Icon(Icons.edit_note_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = true,
  }) : this._(
          type: _LnFormButtonType.enableEditing,
          text: _defaultOr(text, _LnFormButtonType.enableEditing),
          icon: icon,
          tooltip: tooltip,
          onPressed: null,
          effectiveModes: const {FormModes.view},
          style: style,
          primary: primary,
        );

  LnFormButton.cancelEditing({
    String? text = _defaultOfType,
    Widget? icon = const Icon(Icons.close_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          type: _LnFormButtonType.cancelEditing,
          text: _defaultOr(text, _LnFormButtonType.cancelEditing),
          icon: icon,
          tooltip: tooltip,
          onPressed: null,
          effectiveModes: const {FormModes.edit},
          style: style,
          primary: primary,
        );

  LnFormButton.submit({
    String? text = _defaultOfType,
    Widget? icon = const Icon(Icons.save_outlined),
    String? tooltip,
    ButtonStyle? style,
    bool primary = true,
  }) : this._(
          type: _LnFormButtonType.submit,
          text: _defaultOr(text, _LnFormButtonType.submit),
          icon: icon,
          tooltip: tooltip,
          onPressed: null,
          effectiveModes: const {FormModes.edit},
          style: style,
          primary: primary,
        );

  LnFormButton.restore({
    String? text = _defaultOfType,
    Widget? icon = const Icon(Icons.settings_backup_restore_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          type: _LnFormButtonType.restore,
          text: _defaultOr(text, _LnFormButtonType.restore),
          icon: icon,
          tooltip: tooltip,
          onPressed: null,
          effectiveModes: const {FormModes.edit},
          style: style,
          primary: primary,
        );

  LnFormButton.clear({
    String? text = _defaultOfType,
    Widget? icon = const Icon(Icons.clear_all_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          type: _LnFormButtonType.clear,
          text: _defaultOr(text, _LnFormButtonType.clear),
          icon: icon,
          tooltip: tooltip,
          onPressed: null,
          effectiveModes: const {FormModes.edit},
          style: style,
          primary: primary,
        );

  static String? _defaultOr(String? text, _LnFormButtonType type) =>
      text == _defaultOfType
          ? switch (type) {
              _LnFormButtonType.enableEditing =>
                LnFormsLocalizations.current.editButton,
              _LnFormButtonType.cancelEditing =>
                LnFormsLocalizations.current.cancelButton,
              _LnFormButtonType.submit =>
                LnFormsLocalizations.current.saveButton,
              _LnFormButtonType.restore =>
                LnFormsLocalizations.current.restoreButton,
              _LnFormButtonType.clear =>
                LnFormsLocalizations.current.resetButton,
            }
          : text;

  @override
  State<LnFormButton> createState() => LnFormButtonState();
}

class LnFormButtonState extends LnState<LnFormButton> {
  late FocusNode _focusNode;
  bool _inProgress = false;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
  }

  @override
  void deactivate() {
    _LnFormScope.maybeOf(context)?._unregisterButton(this);
    super.deactivate();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = _LnFormScope.maybeOf(context)?.._registerButton(this);
    assert(form != null,
        "No LnForm found in context. LnFormButton widgets cannot be used without the LnForm");
    final controller = form!.controller;

    FormModes currentFormMode =
        controller.readOnly ? FormModes.view : FormModes.edit;
    if (!widget.effectiveModes.contains(currentFormMode)) {
      return const SizedBox.shrink();
    }

    final FutureOr Function()? onPressed;
    if (widget._type == null) {
      onPressed =
          widget.onPressed == null ? null : () => widget.onPressed!(controller);
    } else {
      onPressed = switch (widget._type!) {
        _LnFormButtonType.cancelEditing => () => controller.readOnly = false,
        _LnFormButtonType.enableEditing => () => controller.readOnly = true,
        _LnFormButtonType.clear => controller.clear,
        _LnFormButtonType.restore => controller.restore,
        _LnFormButtonType.submit => controller.submit,
      };
    }

    var computedOnPressed = !controller.enabled || controller.inProgress
        ? null
        : () async {
            _focusNode.requestFocus();
            if (!controller.progressOverlay) {
              _inProgress = true;
              rebuild();
            }
            var result = await controller._wait(onPressed!);
            if (_inProgress) {
              _inProgress = false;
              rebuild();
            }
            return result;
          };

    if (widget.text == null) {
      return widget.primary
          ? IconButton.filled(
              onPressed: computedOnPressed,
              icon: progressIndicatorIconWidget!,
              focusNode: _focusNode,
              style: widget.style,
            )
          : IconButton(
              onPressed: computedOnPressed,
              icon: progressIndicatorIconWidget!,
              focusNode: _focusNode,
              style: widget.style,
            );
    } else if (widget.icon == null) {
      return widget.primary
          ? FilledButton(
              onPressed: computedOnPressed,
              child: progressIndicatorTextWidget!,
              focusNode: _focusNode,
              style: widget.style,
            )
          : TextButton(
              onPressed: computedOnPressed,
              child: progressIndicatorTextWidget!,
              focusNode: _focusNode,
              style: widget.style,
            );
    } else {
      return widget.primary
          ? FilledButton.icon(
              onPressed: computedOnPressed,
              icon: progressIndicatorIconWidget!,
              label: Text(widget.text!),
              focusNode: _focusNode,
              style: widget.style,
            )
          : TextButton.icon(
              onPressed: computedOnPressed,
              icon: progressIndicatorIconWidget!,
              label: Text(widget.text!),
              focusNode: _focusNode,
              style: widget.style,
            );
    }
  }

  Widget? get progressIndicatorIconWidget => widget.icon == null
      ? null
      : ProgressIndicatorWidget(
          inProgress: _inProgress,
          widget: widget.icon!,
        );

  Widget? get progressIndicatorTextWidget => widget.text == null
      ? null
      : ProgressIndicatorWidget(
          inProgress: _inProgress,
          widget: Text(widget.text!),
        );

  Color get primaryDisabledOnColor => _calculateOnColor(
        widget.style,
        Theme.of(context).filledButtonTheme.style,
        Theme.of(context).colorScheme.onBackground,
      );

  Color get disabledOnColor => _calculateOnColor(
        widget.style,
        Theme.of(context).textButtonTheme.style,
        Theme.of(context).colorScheme.onBackground,
      );

  Color _calculateOnColor(
          ButtonStyle? style, ButtonStyle? defaultStyle, Color defaultColor) =>
      (style != null
          ? _disabledColorOf(style)
          : _disabledColorOf(defaultStyle)) ??
      defaultColor;

  Color? _disabledColorOf(ButtonStyle? style) =>
      (style?.iconColor ?? style?.foregroundColor)
          ?.resolve({MaterialState.disabled});
}
