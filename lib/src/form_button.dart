part of 'form.dart';

const _kDefaultTextOfAction = "\$\$DEF\$\$";

typedef ActionGetter = FormAction Function(LnFormState);

class LnFormButton extends StatefulWidget {
  LnFormButton({
    String? text,
    this.icon,
    this.tooltip,
    required FormActionCallable? onPressed,
    this.style,
    this.primary = true,
    this.showOnReadOnlyMode = true,
    this.showOnEditMode = true,
  })  : assert(text != null || icon != null),
        resolveText = ((_) => text),
        actionOf =
            ((formState) => FormAction(form: formState, callable: onPressed));

  const LnFormButton._({
    required this.actionOf,
    required this.resolveText,
    required this.icon,
    required this.tooltip,
    required this.style,
    required this.primary,
    this.showOnReadOnlyMode = false,
    this.showOnEditMode = false,
  });

  LnFormButton.enableEditing({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.edit_note_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = true,
    required FormActionCallable? onPressed,
  }) : this._(
          actionOf: ((formState) =>
              FormAction(form: formState, callable: onPressed)),
          resolveText: (l) => _textOrDefault(text, l.editButton),
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
          showOnReadOnlyMode: true,
        );

  LnFormButton.cancelEditing({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.close_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
    required FormActionCallable? onPressed,
  }) : this._(
          actionOf: ((formState) =>
              FormAction(form: formState, callable: onPressed)),
          resolveText: (l) => _textOrDefault(text, l.cancelButton),
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
          showOnEditMode: true,
        );

  LnFormButton.submit({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.save_outlined),
    String? tooltip,
    ButtonStyle? style,
    bool primary = true,
  }) : this._(
          actionOf: (form) => form.submit,
          resolveText: (l) => _textOrDefault(text, l.saveButton),
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
          showOnEditMode: true,
        );

  LnFormButton.restore({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.settings_backup_restore_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          actionOf: (form) => form.restore,
          resolveText: (l) => _textOrDefault(text, l.restoreButton),
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
          showOnEditMode: true,
        );

  LnFormButton.clear({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.clear_all_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          actionOf: (form) => form.clear,
          resolveText: (l) => _textOrDefault(text, l.resetButton),
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
          showOnEditMode: true,
        );

  static String? _textOrDefault(String? text, String defaultText) {
    return text == _kDefaultTextOfAction ? defaultText : text;
  }

  final String? Function(LnFormsLocalizations) resolveText;
  final Widget? icon;
  final String? tooltip;
  final ButtonStyle? style;
  final bool primary;
  final bool showOnReadOnlyMode;
  final bool showOnEditMode;

  final ActionGetter actionOf;

  @override
  State<LnFormButton> createState() => LnFormButtonState();
}

class LnFormButtonState extends LnState<LnFormButton> {
  final FocusNode _focusNode = FocusNode();
  LnFormState? _form;

  Text? textOf(FormAction action) {
    final text = widget.resolveText(LnFormsLocalizations.current);
    return text == null ? null : Text(text);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = LnForm.of(context);
    if (form != _form) {
      _form?._unregisterButton(this);
      _form = form.._registerButton(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(_form != null,
        "No LnForm found in context. LnFormButton widgets cannot be used without the LnForm");
    final form = _form!;

    final action = widget.actionOf(form);
    final text = textOf(action);

    return ListenableBuilder(
      listenable: _focusNode,
      builder: (context, child) => Visibility(
        visible: form.computedState.readOnly
            ? widget.showOnReadOnlyMode
            : widget.showOnEditMode,
        child: _ProgressButton(
          primary: widget.primary,
          progress: form.isActionInProgress(action),
          text: text,
          icon: widget.icon,
          style: widget.style,
          onPressed: action.callable,
          focusNode: _focusNode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _form?._unregisterButton(this);
    _focusNode.dispose();
    super.dispose();
  }
}

class _ProgressButton extends Builder {
  _ProgressButton({
    required bool primary,
    required bool progress,
    Widget? text,
    Widget? icon,
    ButtonStyle? style,
    VoidCallback? onPressed,
    FocusNode? focusNode,
  })  : assert(text != null || icon != null),
        super(builder: (context) {
          bool hasText = text != null;
          bool hasIcon = icon != null;
          style ??= _defaultStyleOf(context, hasIcon && hasText);

          Widget child = ProgressIndicatorWidget(
            progress: progress,
            widget: hasIcon ? icon : text!,
          );

          if (hasIcon && hasText) {
            child = SpacedRow(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                text,
              ],
            );
          }

          return primary
              ? FilledButton(
                  onPressed: onPressed,
                  focusNode: focusNode,
                  style: style,
                  child: child,
                )
              : TextButton(
                  onPressed: onPressed,
                  focusNode: focusNode,
                  style: style,
                  child: child,
                );
        });

  static ButtonStyle _defaultStyleOf(BuildContext context, bool withIcon) {
    double m = withIcon ? 1.5 : 1.0;
    return FilledButton.styleFrom(
      minimumSize: Size(kMinInteractiveDimension, kMinInteractiveDimension),
      padding: ButtonStyleButton.scaledPadding(
        EdgeInsetsDirectional.fromSTEB(16, 0, 16 * m, 0),
        EdgeInsetsDirectional.fromSTEB(8, 0, 8 * m, 0),
        EdgeInsetsDirectional.fromSTEB(4, 0, 4 * m, 0),
        MediaQuery.textScalerOf(context).scale(1),
      ),
    );
  }
}
