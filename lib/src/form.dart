import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ln_alerts/ln_alerts.dart';
import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/ln_forms.dart';
import 'package:ln_forms/src/utilities/extensions.dart';
import 'package:ln_forms/src/utilities/logger.dart';
import 'package:ln_forms/src/widgets/empty_readonly_field.dart';
import 'package:universal_platform/universal_platform.dart';

import 'package:ln_dialogs/ln_dialogs.dart';

part 'form_builder.dart';
part 'form_button.dart';
part 'form_controller.dart';
part 'form_field.dart';
part 'form_wrapper.dart';
part 'future_form_field.dart';
part 'unsaved_forms_observer.dart';

enum FormModes { view, edit }

enum ButtonsLocation { bottomAppBar, afterFields }

class LnForm extends StatefulWidget {
  final bool scrollable;
  final ScrollController? scrollController;

  //final Widget? child;
  final WillPopCallback? onWillPop;
  final VoidCallback? onChanged;

  final LnFormController? controller;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final bool? card;
  final bool? useSafeAreaForBottom;
  final bool? alertHost;

  // Wrapper props-
  final Widget child;
  final bool _hasWrapper;
  final bool showUnsavedChangesMark;
  final bool notifyUnsavedChanges;

  const LnForm({
    super.key,
    this.onWillPop,
    this.onChanged,
    required this.child,
    this.scrollable = true,
    this.scrollController,
    this.controller,
    this.showUnsavedChangesMark = false,
    this.notifyUnsavedChanges = false,
  })  : padding = null,
        margin = null,
        card = false,
        useSafeAreaForBottom = false,
        alertHost = false,
        _hasWrapper = false;

  const LnForm.wrapper({
    super.key,
    this.onWillPop,
    this.onChanged,
    required this.child,
    this.scrollable = true,
    this.scrollController,
    this.controller,
    this.padding = formPadding,
    this.margin = formMargin,
    this.card = true,
    this.useSafeAreaForBottom = true,
    this.alertHost = true,
    this.showUnsavedChangesMark = false,
    this.notifyUnsavedChanges = false,
  }) : _hasWrapper = true;

  @override
  State<LnForm> createState() => _LnProviderFormState();
}

class _LnProviderFormState extends _LnFormState
    with _LnUnsavedStateProviderForm {
  @override
  bool get observeUnsavedChanges => widget.notifyUnsavedChanges;
}

class _LnFormState extends State<LnForm> {
  int _generation = 0;

  final Set<LnFormFieldState<dynamic>> _fields = <LnFormFieldState<dynamic>>{};
  final Set<LnFormButtonState> _buttons = <LnFormButtonState>{};

  ScrollController? _internalScrollController;
  ScrollController get scrollController =>
      widget.scrollController ?? _internalScrollController!;

  LnFormController? _internalController;
  LnFormController get controller => widget.controller ?? _internalController!;

  int get unsavedFieldsCount => _fields.where((f) => f.unsaved).length;

  //late FormModes _currentMode = widget.modes.first;

  void _fieldDidChange() {
    widget.onChanged?.call();
    _rebuild();
  }

  void _register(LnFormFieldState<dynamic> field) => _fields.add(field);

  void _unregister(LnFormFieldState<dynamic> field) => _fields.remove(field);

  void _registerButton(LnFormButtonState button) => _buttons.add(button);

  void _unregisterButton(LnFormButtonState button) => _buttons.remove(button);

  void _rebuildButtons() {
    for (var button in _buttons) {
      button.rebuild();
    }
  }

  void _rebuildFields() {
    for (var field in _fields) {
      field.rebuild();
    }
  }

  void _save() {
    _log("save");
    for (final LnFormFieldState<dynamic> field in _fields) {
      field.save();
    }
  }

  void _reset() {
    _log("reset");
    for (final LnFormFieldState<dynamic> field in _fields) {
      field.reset();
    }
    _fieldDidChange();
  }

  bool _validate() {
    _log("_validate");
    bool hasError = false;
    String errorMessage = '';
    for (final LnFormFieldState<dynamic> field in _fields) {
      hasError = !field.validate() || hasError;
      errorMessage += field.errorText ?? '';
    }

    if (errorMessage.isNotEmpty) {
      final TextDirection directionality = Directionality.of(context);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        unawaited(Future<void>(() async {
          await Future<void>.delayed(const Duration(seconds: 1));
          SemanticsService.announce(errorMessage, directionality,
              assertiveness: Assertiveness.assertive);
        }));
      } else {
        SemanticsService.announce(errorMessage, directionality,
            assertiveness: Assertiveness.assertive);
      }
    }
    return !hasError;
  }

  @override
  void initState() {
    super.initState();

    if (widget.scrollController == null) {
      _internalScrollController = ScrollController()
        ..addListener(_handleScrollChange);
    }

    if (widget.controller == null) {
      _internalController = LnFormController(onSubmit: null);
    }
  }

  @override
  void dispose() {
    _internalScrollController
      ?..removeListener(_handleScrollChange)
      ..dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _handleScrollChange() {}

  @override
  void didUpdateWidget(covariant LnForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScrollChange);
      widget.scrollController?.addListener(_handleScrollChange);

      if (oldWidget.scrollController != null &&
          widget.scrollController == null) {
        _internalScrollController = ScrollController()
          ..addListener(_handleScrollChange);
      }

      if (widget.scrollController != null &&
          oldWidget.scrollController == null) {
        _internalScrollController
          ?..removeListener(_handleScrollChange)
          ..dispose();
        _internalScrollController = null;
      }
    }

    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller != null && widget.controller == null) {
        _internalController = LnFormController(onSubmit: null);
      }

      if (widget.controller != null && oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
    }
  }

  Widget _buildChild(BuildContext context) {
    var alertHost = LnAlertHost.maybeOf(context);
    controller._setFormContext(this, alertHost);

    Widget child = widget.child;

    if (widget.showUnsavedChangesMark) {
      child = Stack(
        children: [
          widget.child,
          if (unsavedFieldsCount > 0)
            Positioned(
              right: 0,
              child: _buildRotatedUnsavedChangesBox(context),
            ),
        ],
      );
    }

    return child;
  }

  Widget _buildRotatedUnsavedChangesBox(BuildContext context) {
    final alertColors = LnAlertsTheme.of(context).colorsOf(AlertType.warning);
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
              "KAYDEDİLMEDİ",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  Widget _buildVerticalUnsavedChangesBox(BuildContext context) {
    final alertColors = LnAlertsTheme.of(context).colorsOf(AlertType.warning);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: alertColors.background,
        borderRadius: BorderRadius.all(
          Radius.circular(8),
        ),
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
            "KAYDEDİLMEDİ",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: alertColors.foreground,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget result;
    if (widget._hasWrapper) {
      result = LnFormWrapper(
        padding: widget.padding ?? EdgeInsets.zero,
        margin: widget.margin ?? EdgeInsets.zero,
        card: widget.card ?? false,
        useSafeAreaForBottom: widget.useSafeAreaForBottom ?? false,
        alertHost: widget.alertHost ?? true,
        child: Builder(builder: _buildChild),
      );
    } else {
      result = _buildChild(context);
    }

    if (widget.scrollable) {
      result = OverlimitScrollController(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: result,
        ),
      );
    }

    result = WillPopScope(
      onWillPop: widget.onWillPop,
      child: result,
    );

    return _LnFormScope(
      formState: this,
      generation: _generation,
      child: FocusScope(
        onFocusChange: null,
        child: result,
      ),
    );
  }

  _log(String functionName) {
    if (kLoggingEnabled) {
      FormLog.d("#$_generation[FORM]", functionName, 2, fieldName: null);
    }
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {
      ++_generation;
    });
  }
}

class _LnFormScope extends InheritedWidget {
  const _LnFormScope({
    required super.child,
    required this.formState,
    required this.generation,
  });

  final _LnFormState formState;
  final int generation;

  @override
  bool updateShouldNotify(_LnFormScope old) => generation != old.generation;

  static _LnFormState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LnFormScope>()?.formState;
}

class _InheritState {
  final bool enabled;
  final bool readOnly;
  final bool? clearable;
  final bool? restoreable;

  bool get active => !readOnly && enabled;

  const _InheritState({
    this.enabled = true,
    this.readOnly = false,
    this.clearable,
    this.restoreable,
  });

  _InheritState copyWith({
    bool? enabled,
    bool? readOnly,
    bool? clearable,
    bool? restoreable,
  }) {
    return _InheritState(
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      clearable: clearable ?? this.clearable,
      restoreable: restoreable ?? this.restoreable,
    );
  }

  ScopedState scope(_InheritState? scopeState) {
    final nnScopeState = scopeState ?? _InheritState();

    return ScopedState(
      enabled: enabled && nnScopeState.enabled,
      readOnly: readOnly || nnScopeState.readOnly,
      clearable: clearable ?? nnScopeState.clearable ?? true,
      restoreable: restoreable ?? nnScopeState.restoreable ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _InheritState &&
      other.runtimeType == runtimeType &&
      other.enabled == enabled &&
      other.readOnly == readOnly &&
      other.clearable == clearable &&
      other.restoreable == restoreable;

  @override
  String toString() {
    return '_InheritState(enabled: $enabled, readOnly: $readOnly, clearable: $clearable, restoreable: $restoreable)';
  }

  @override
  int get hashCode => Object.hash(enabled, readOnly, clearable, restoreable);
}

class ScopedState {
  final bool enabled;
  final bool readOnly;
  final bool clearable;
  final bool restoreable;

  bool get active => !readOnly && enabled;

  const ScopedState({
    this.enabled = true,
    this.readOnly = false,
    this.clearable = true,
    this.restoreable = true,
  });
}
