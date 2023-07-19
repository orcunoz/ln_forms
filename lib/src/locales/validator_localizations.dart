import 'package:ln_core/ln_core.dart';

import 'locale_en.dart';
import 'locale_tr.dart';

final validatorLocalizations = LnLocalizationScope<ValidatorLocale>([
  ValidatorLocaleEn(),
  ValidatorLocaleTr(),
]);

abstract class ValidatorLocale extends LnLocale {
  const ValidatorLocale(super.languageCode);

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
