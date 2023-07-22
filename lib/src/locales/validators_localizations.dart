import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';

import 'locale_en.dart';
import 'locale_tr.dart';

abstract class LnValidatorsLocalizations extends LnLocalizations {
  const LnValidatorsLocalizations(super.languageCode);

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

  static const delegate = LnLocalizationsDelegate<LnValidatorsLocalizations>(
    [ValidatorsLocaleEn(), ValidatorsLocaleTr()],
    _setInstance,
  );

  static void _setInstance(LnValidatorsLocalizations instance) =>
      _instance = instance;
  static LnValidatorsLocalizations? _instance;
  static LnValidatorsLocalizations get current {
    assert(_instance != null,
        "No ValidatorLocalizations instance created before!");
    return _instance as LnValidatorsLocalizations;
  }

  static LnValidatorsLocalizations of(BuildContext context) =>
      Localizations.of<LnValidatorsLocalizations>(
          context, LnValidatorsLocalizations)!;
}
