part of 'form.dart';

mixin LnUnsavedObserverMixin<T> {
  void onUnsavedRegistrationsChanged(Iterable<T> list);
}

class LnUnsavedObserver<T> extends InheritedWidget
    with LnUnsavedObserverMixin<T> {
  LnUnsavedObserver({
    required super.child,
    required this.onUnsavedStatesChanged,
  });

  final void Function(Iterable<T>) onUnsavedStatesChanged;
  final _list = <T>{};

  void registerUnsaved(T unsaved) {
    _list.add(unsaved);
    onUnsavedRegistrationsChanged(_list);
  }

  void unregisterUnsaved(T unsaved) {
    _list.remove(unsaved);
    onUnsavedRegistrationsChanged(_list);
  }

  @override
  void onUnsavedRegistrationsChanged(Iterable<T> list) {
    onUnsavedStatesChanged(list);
  }

  @override
  bool updateShouldNotify(LnUnsavedObserver<T> oldWidget) =>
      onUnsavedStatesChanged != oldWidget.onUnsavedStatesChanged;

  static LnUnsavedObserver<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LnUnsavedObserver<T>>();
}

abstract class UnsavedChangesNotifiable {
  bool get notifyUnsavedChanges;
}

abstract class UnsavedChangesNotifiableWidget
    implements StatefulWidget, UnsavedChangesNotifiable {}

abstract class UnsavedChangesNotifier {
  bool get hasUnsavedChanges;
  void notifyUnsavedChanges();
}

mixin UnsavedChangesNotifiableStateMixin<
        W extends UnsavedChangesNotifiableWidget> on State<W>
    implements UnsavedChangesNotifier {
  LnUnsavedObserver<State<W>>? _observer;

  void _setObserver(LnUnsavedObserver<State<W>>? observer) {
    _observer?.unregisterUnsaved(this);
    _observer = observer;
    notifyUnsavedChanges();
  }

  @mustCallSuper
  @override
  void notifyUnsavedChanges() {
    if (widget.notifyUnsavedChanges) {
      if (hasUnsavedChanges) {
        _observer?.registerUnsaved(this);
      } else {
        _observer?.unregisterUnsaved(this);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = LnUnsavedObserver.maybeOf<State<W>>(context);
    if (_observer != observer) {
      _setObserver(observer);
    }
  }

  @override
  void dispose() {
    _setObserver(null);
    super.dispose();
  }

  Widget _buildRotatedUnsavedText(BuildContext context) {
    final theme = Theme.of(context);
    final alertColors = theme.alertsTheme.colorsOf(AlertType.warning);
    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: alertColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SpacedRow(
          spacing: 4,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: alertColors.foreground,
            ),
            Text(
              LnFormsLocalizations.current.unsaved,
              style: theme.textTheme.labelSmall?.copyWith(
                color: alertColors.foreground,
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
  Widget _buildVerticalUnsavedText(BuildContext context) {
    final theme = Theme.of(context);
    final alertColors = theme.alertsTheme.colorsOf(AlertType.warning);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: alertColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SpacedColumn(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: alertColors.foreground,
          ),
          VerticalText(
            LnFormsLocalizations.current.unsaved,
            style: theme.textTheme.labelSmall?.copyWith(
              color: alertColors.foreground,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
