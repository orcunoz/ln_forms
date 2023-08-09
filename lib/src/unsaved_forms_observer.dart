part of 'form.dart';

class LnUnsavedFormsObserver extends StatefulWidget {
  final Widget child;
  final void Function(Iterable<LnFormController>) unsavedFormsCountChanged;

  const LnUnsavedFormsObserver({
    super.key,
    required this.child,
    required this.unsavedFormsCountChanged,
  });

  @override
  State<LnUnsavedFormsObserver> createState() => _LnUnsavedFormsObserverState();
}

class _LnUnsavedFormsObserverState extends State<LnUnsavedFormsObserver> {
  final Set<_LnFormState> _unsavedForms = <_LnFormState>{};

  void _notify() {
    widget.unsavedFormsCountChanged(_unsavedForms.map((e) => e.controller));
  }

  void _registerUnsavedForms(_LnFormState form) {
    _unsavedForms.add(form);
    _notify();
  }

  void _unregisterUnsavedForms(_LnFormState form) {
    _unsavedForms.remove(form);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return _LnUnsavedFormsObserverScope(
      state: this,
      child: widget.child,
    );
  }
}

class _LnUnsavedFormsObserverScope extends InheritedWidget {
  final _LnUnsavedFormsObserverState state;
  const _LnUnsavedFormsObserverScope({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_LnUnsavedFormsObserverScope old) =>
      state != old.state;

  static _LnUnsavedFormsObserverState? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_LnUnsavedFormsObserverScope>()
      ?.state;
}

mixin _LnUnsavedStateProviderForm on _LnFormState {
  bool _registeredToUnsavedFormsObserver = false;
  bool get observeUnsavedChanges;

  void _registerUnsavedFormsObserver() {
    if (!_registeredToUnsavedFormsObserver && observeUnsavedChanges) {
      _LnUnsavedFormsObserverScope.maybeOf(context)
          ?._registerUnsavedForms(this);
      _registeredToUnsavedFormsObserver = true;
    }
  }

  void _unregisterUnsavedFormsObserver() {
    if (_registeredToUnsavedFormsObserver) {
      _LnUnsavedFormsObserverScope.maybeOf(context)
          ?._unregisterUnsavedForms(this);
      _registeredToUnsavedFormsObserver = false;
    }
  }

  @override
  void deactivate() {
    _unregisterUnsavedFormsObserver();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (unsavedFieldsCount > 0) {
      _registerUnsavedFormsObserver();
    } else {
      _unregisterUnsavedFormsObserver();
    }

    return super.build(context);
  }
}
