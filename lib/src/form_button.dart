part of 'form.dart';

const _kDefaultTextOfAction = "\$\$DEF\$\$";

typedef ActionGetter = FormAction Function(LnFormState);

class LnFormButton extends StatefulWidget {
  LnFormButton({
    this.text,
    this.icon,
    this.tooltip,
    required FormActionCallable? onPressed,
    this.style,
    this.primary = true,
    this.showOnReadOnly = false,
  }) : actionOf =
            ((formState) => FormAction(form: formState, callable: onPressed));

  const LnFormButton._({
    required this.actionOf,
    required this.text,
    required this.icon,
    required this.tooltip,
    required this.style,
    required this.primary,
    this.showOnReadOnly = true,
  }) : assert(text != null || icon != null);

  LnFormButton.enableEditing({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.edit_note_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = true,
  }) : this._(
          actionOf: (form) => form.enableEditing,
          text: text,
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
        );

  LnFormButton.cancelEditing({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.close_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          actionOf: (form) => form.cancelEditing,
          text: text,
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
        );

  LnFormButton.submit({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.save_outlined),
    String? tooltip,
    ButtonStyle? style,
    bool primary = true,
  }) : this._(
          actionOf: (form) => form.submit,
          text: text,
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
        );

  LnFormButton.restore({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.settings_backup_restore_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          actionOf: (form) => form.restore,
          text: text,
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
        );

  LnFormButton.clear({
    String? text = _kDefaultTextOfAction,
    Widget? icon = const Icon(Icons.clear_all_rounded),
    String? tooltip,
    ButtonStyle? style,
    bool primary = false,
  }) : this._(
          actionOf: (form) => form.clear,
          text: text,
          icon: icon,
          tooltip: tooltip,
          style: style,
          primary: primary,
        );

  final String? text;
  final Widget? icon;
  final String? tooltip;
  final ButtonStyle? style;
  final bool primary;
  final bool showOnReadOnly;

  final ActionGetter actionOf;

  @override
  State<LnFormButton> createState() => LnFormButtonState();
}

class LnFormButtonState extends LnState<LnFormButton> {
  final FocusNode _focusNode = FocusNode();
  LnFormState? _form;

  Text? textOf(FormAction action) {
    final text = widget.text == _kDefaultTextOfAction
        ? action.defaultButtonText
        : widget.text;

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
        visible: switch (form.computedState.readOnly) {
          true => action == form.enableEditing || widget.showOnReadOnly,
          false => action != form.enableEditing,
        },
        child: _ProgressButton(
          primary: widget.primary,
          progress: form.isActionInProgress(action),
          text: text,
          icon: widget.icon,
          style: widget.style,
          onPressed: action.enabled ? action.call : null,
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
