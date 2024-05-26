part of 'form.dart';

class LnUnsavedObserver<T> extends InheritedWidget {
  LnUnsavedObserver({
    required super.child,
    required this.onUnsavedStatesChanged,
  });

  final void Function(Iterable<T>) onUnsavedStatesChanged;
  final _list = <T>{};

  void registerAsUnsaved(T unsaved) {
    _list.add(unsaved);
    onUnsavedStatesChanged(_list);
  }

  void unregister(T unsaved) {
    _list.remove(unsaved);
    onUnsavedStatesChanged(_list);
  }

  @override
  bool updateShouldNotify(LnUnsavedObserver<T> oldWidget) =>
      onUnsavedStatesChanged != oldWidget.onUnsavedStatesChanged;

  static LnUnsavedObserver<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LnUnsavedObserver<T>>();
}

class LnUnsavedNotifier<T> extends StatefulWidget {
  const LnUnsavedNotifier({
    super.key,
    required this.hasUnsavedChanges,
    required this.child,
  });

  final bool hasUnsavedChanges;
  final Widget child;

  @override
  State<LnUnsavedNotifier> createState() => _LnUnsavedNotifierState<T>();
}

class _LnUnsavedNotifierState<T> extends State<LnUnsavedNotifier<T>> {
  LnUnsavedObserver? _observer;

  void _setObserver(LnUnsavedObserver? observer) {
    _observer?.unregister(this);
    _observer = observer;
    notifyState();
  }

  void notifyState() {
    if (widget.hasUnsavedChanges) {
      _observer?.registerAsUnsaved(this);
    } else {
      _observer?.unregister(this);
    }
  }

  @override
  void didUpdateWidget(LnUnsavedNotifier<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.hasUnsavedChanges != oldWidget.hasUnsavedChanges) {
      notifyState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final observer = LnUnsavedObserver.maybeOf<T>(context);
    if (_observer != observer) {
      _setObserver(observer);
    }
  }

  @override
  void dispose() {
    _setObserver(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  static Widget _buildRotatedUnsavedText(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceVariant;
    final foregroundColor = theme.colorScheme.onSurfaceVariant;

    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SpacedRow(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: foregroundColor,
            ),
            Text(
              LnFormsLocalizations.current.unsaved,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  static Widget _buildVerticalUnsavedText(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceVariant;
    final foregroundColor = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SpacedColumn(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: foregroundColor,
          ),
          VerticalText(
            LnFormsLocalizations.current.unsaved,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
