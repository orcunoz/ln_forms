part of 'form.dart';

class _LnFormScope extends InheritedWidget {
  const _LnFormScope({
    required super.child,
    required this.state,
  });

  final LnFormState state;

  @override
  bool updateShouldNotify(_LnFormScope old) => state != old.state;
}
