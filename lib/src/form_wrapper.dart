part of 'form.dart';

class LnFormWrapper extends StatelessWidget {
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool card;
  final bool useSafeAreaForBottom;
  final bool alertHost;
  final Widget child;

  LnFormWrapper({
    super.key,
    this.padding = formPadding,
    this.margin = formMargin,
    this.card = true,
    this.useSafeAreaForBottom = true,
    this.alertHost = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    Widget result = child;

    if (padding != EdgeInsets.zero) {
      result = Padding(
        padding: padding,
        child: result,
      );
    }

    if (alertHost) {
      result = LnAlertHost(
        defaultWidget: AlertWidget.flat,
        child: result,
      );
    }

    if (card) {
      result = Card(
        child: result,
        margin: EdgeInsets.zero,
      );
    }

    result = Responsive(
      margin: margin +
          (useSafeAreaForBottom
              ? mediaQuery.safeBottomPadding
              : EdgeInsets.zero),
      child: result,
    );

    return result;
  }
}
