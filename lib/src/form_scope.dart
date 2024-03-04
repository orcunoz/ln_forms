part of 'form.dart';

class LnFormScopeExtender extends StatelessWidget {
  const LnFormScopeExtender({
    required this.formController,
    required this.child,
  });

  final Widget child;
  final LnFormController formController;

  @override
  Widget build(BuildContext context) {
    return _LnFormScope(
      controller: formController,
      child: child,
    );
  }
}

class _LnFormScope extends InheritedWidget {
  const _LnFormScope({
    required super.child,
    required this.controller,
  });

  final LnFormController controller;

  @override
  bool updateShouldNotify(_LnFormScope old) => controller != old.controller;
}
