part of 'form.dart';

class InputOption {
  final String label;
  final dynamic value;

  const InputOption(this.label, this.value);
}

/*abstract class FormFields {
  static Widget input({
    required String type,
    String? label,
    List<InputOption>? options,
    dynamic initialValue,
    void Function(dynamic)? onChanged,
    bool readOnly = false,
    bool? enabled,
  }) =>
      switch (type) {
        "text" => TextInputFormField(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
          ),
        "date" => DateInputFormField(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
          ),
        "time" => TimeInputFormField(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
          ),
        "select" => DropdownFormField<InputOption>(
            decoration: LnDecoration(
              label: label,
            ),
            initialValue: initialValue,
            onChanged: onChanged,
            readOnly: readOnly,
            enabled: enabled,
            itemLabelBuilder: (e) => e?.label ?? "",
            items: options!,
          ),
        _ => throw Exception("Undefined input type"),
      };
}
*/

class LnFormBuilder {
  final BuildContext context;
  final ThemeData theme;
  final FormModes mode;

  const LnFormBuilder({
    required this.context,
    required this.theme,
    required this.mode,
  });

  static Widget title(BuildContext context, String title) {
    return Container(
      alignment: Alignment.topLeft,
      child: Text(
        title,
        style: TextStyle(
            fontSize: 13, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget layout({
    Key? key,
    EdgeInsets padding = formPadding,
    EdgeInsets margin = formMargin,
    bool card = true,
    bool useSafeAreaForBottom = true,
    bool alertHost = true,
    required Widget child,
  }) =>
      LnFormWrapper(
        key: key,
        padding: padding,
        margin: margin,
        card: card,
        useSafeAreaForBottom: useSafeAreaForBottom,
        alertHost: alertHost,
        child: child,
      );

  BottomAppBar? bottomAppBar(
      List<LnFormButton> buttons, List<FocusNode> focusNodes) {
    final activeButtons = buttons.where((b) => b.effectiveModes.contains(mode));
    final normalButtons =
        activeButtons.where((b) => b._type != _LnFormButtonType.submit);
    final primaryButtons =
        activeButtons.where((b) => b._type == _LnFormButtonType.submit);

    return activeButtons.isEmpty
        ? null
        : BottomAppBar(
            padding: EdgeInsets.symmetric(vertical: 8),
            elevation: .0,
            clipBehavior: Clip.antiAlias,
            child: Responsive(
              alignment: Alignment.topCenter,
              //margin: widget.margin.symetricScale(vertical: 0),
              child: Row(
                children: [
                  ...normalButtons,
                  Center(),
                  ...primaryButtons,
                ],
              ),
            ),
          );
  }

  Widget? actionButtons(
      List<LnFormButton> buttons, List<FocusNode> focusNodes) {
    final activeButtons = buttons.where((b) => b.effectiveModes.contains(mode));

    return activeButtons.isEmpty
        ? null
        : Center(
            child: SpacedWrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: <Widget>[
                for (var button in activeButtons)
                  if (button.effectiveModes.contains(mode)) button,
              ],
            ),
          );
  }

  Widget wrap(
    List<Widget> children, {
    double spacing = formHorizontalSpacing,
    double runSpacing = formVerticalSpacing,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }

  Widget bottomAppBarWrapper(Widget? bottomAppBar, Widget child) {
    final barHeight =
        kToolbarHeight + MediaQuery.of(context).safeBottomPadding.bottom;
    const animationDuration = Duration(milliseconds: 300);
    final showBar = bottomAppBar != null;
    return Stack(
      children: [
        AnimatedContainer(
          //transform: Matrix4.translationValues(0, _translationY ?? 0, 0), // TODO
          duration: animationDuration,
          curve: Curves.easeInOut,
          padding: EdgeInsets.only(bottom: showBar ? kToolbarHeight + .5 : 0),
          child: child,
        ),
        AnimatedPositioned(
          duration: animationDuration,
          height: barHeight,
          bottom: showBar ? 0 : -barHeight,
          right: 0,
          left: 0,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: .5,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            height: barHeight,
            child: bottomAppBar,
          ),
        ),
      ],
    );
  }

  static ButtonStyle _floatingActionButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = theme.colorScheme.onPrimaryContainer;
    final backgroundColor = theme.colorScheme.primaryContainer;

    return (theme.filledButtonTheme.style ?? ButtonStyle()).copyWith(
      elevation: MaterialStatePropertyAll(.0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: foregroundColor.material,
      backgroundColor: backgroundColor.material,
      shape: MaterialStatePropertyAll(
        theme.cardTheme.shape == null
            ? null
            : RoundedRectangleBorder(
                borderRadius: theme.cardTheme.shape!.borderRadius ??
                    BorderRadius.all(Radius.circular(8)),
                side: theme.cardTheme.shape!.borderSide ??
                    BorderSide(
                      width: .5,
                      color: foregroundColor,
                    ),
              ),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16).material,
    );
  }

  static Widget primaryActionButton({
    required BuildContext context,
    Widget? icon,
    String? text,
    String? tooltip,
    Function()? onPressed,
    FocusNode? focusNode,
  }) {
    assert(icon != null || text != null);
    final textWidget = text == null ? null : Text(text);
    final style = _floatingActionButtonStyle(context);

    return textWidget == null
        ? IconButton.filled(
            onPressed: onPressed,
            icon: icon!,
            focusNode: focusNode,
            tooltip: tooltip,
            style: style,
          )
        : FilledButton.icon(
            onPressed: onPressed,
            label: textWidget,
            icon: icon!,
            focusNode: focusNode,
            style: style,
          );
  }

  /*List<Widget> _buildBottomAppBarActionButtons(
    BuildContext context,
    FormMode formMode,
    List<FormMode> modes,
    bool enabled,
    Function(FormMode) changeMode,
    Function()? onSubmitPressed,
    String? submitButtonText,
    IconData submitButtonIcon,
    String? editButtonText,
    IconData editButtonIcon,
  ) {
    final focusNodes =
        _getActionButtonFocusNodes(widget.actionButtons.length + 1);
    final ss = LnFormsLocalizations.current;

    return <Widget>[
      for (var (index, buttonData) in widget.actionButtons.indexed)
        if (buttonData.enabledModes.contains(formMode))
          buttonData.build(
            context: context,
            short: false,
            primary: false,
            enabled: enabled,
            busy: false,
            focusNode: focusNodes[index + 1],
            onPressed: switch (buttonData.type) {
              LnFormActionButtonType.clear => _onClickClearFields,
              LnFormActionButtonType.restore => () => ConfirmationDialog.show(
                    context: context,
                    message:
                        ss.areYouSureYouWantToX(ss.restoreChanges).sentenceCase,
                    onSubmit: reset,
                  ),
              _ => null,
            },
          ),
      Expanded(child: SizedBox()),
      if (formMode == FormMode.edit && onSubmitPressed != null)
        _buildPrimaryActionButton(
          icon: ProgressIndicatorIcon(
            icon: submitButtonIcon,
            loading: !enabled,
          ),
          tooltip: LnFormsLocalizations.current.saveButton,
          text: submitButtonText ?? LnFormsLocalizations.current.saveButton,
          onPressed: enabled
              ? () {<<zéü

                  focusNodes[0].requestFocus();
                  onSubmitPressed();
                }
              : null,
          focusNode: focusNodes[0],
        )
      else if (formMode == FormMode.view && modes.contains(FormMode.edit))
        _buildPrimaryActionButton(
          icon: ProgressIndicatorIcon(
            icon: editButtonIcon,
            loading: !enabled,
          ),
          tooltip: editButtonText ?? LnFormsLocalizations.current.editButton,
          text: editButtonText ?? LnFormsLocalizations.current.editButton,
          onPressed: () => changeMode(FormMode.edit),
          focusNode: focusNodes[0],
        ),
    ];
  }*/
}
