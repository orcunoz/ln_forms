import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

import 'locale_en.dart';
import 'locale_tr.dart';

abstract class LnFormsLocalizations extends LnLocalizationsBase
    implements _LnValidatorsLocalizations {
  const LnFormsLocalizations(super.languageCode);

  String get okButton;
  String get saveButton;
  String get editButton;
  String get cancelButton;
  String get restoreButton;
  String get resetButton;
  String get confirmButton;
  String get continueButton;
  String get youHaveAlreadyAddedThis;
  String get clickHereForSelectAnImage;
  String areYouSureYouWantToX(String action);
  String clearX(String s);
  String get restoreChanges;
  String get formFields;
  String get pleaseFixValidationErrors;
  String get unsavedChangesWarning;
  String get htmlEditorNotSupported;
  String get htmlEditorNotSupportedWarning;
  String get unsaved;

  static const delegate = LnLocalizationsDelegate<LnFormsLocalizations>(
    [LnFormsLocaleEn(), LnFormsLocaleTr()],
    LnFormsLocalizations._setInstance,
  );

  static void _setInstance(LnFormsLocalizations instance) =>
      _instance = instance;
  static LnFormsLocalizations? _instance;
  static LnFormsLocalizations get current {
    assert(_instance != null, "No FormsLocalizations instance created before!");
    return _instance!;
  }

  static LnFormsLocalizations of(BuildContext context) =>
      Localizations.of<LnFormsLocalizations>(context, LnFormsLocalizations)!;
}

abstract class _LnValidatorsLocalizations extends LnLocalizationsBase {
  const _LnValidatorsLocalizations(super.languageCode);

  String get theField;
  String fieldCanNotBeEmpty(String field);
  String fieldShouldBeAccepted(String field);
  String fieldRequired(String field);
  String fieldMustBeLengthCharactersLong(String field, int length);
  String fieldMustBeAtLeastLengthCharactersLong(String field, int length);
  String fieldMustBeAtMostLengthCharactersLong(String field, int length);
  String fieldsDontMatch(String fields);
  String fieldAndTheOtherFieldMustBeDifferent(String field, String otherField);
  String get emailFormatIsInvalid;
  String get mobileNumberIsInvalid;
}
