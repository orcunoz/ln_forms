import 'package:ln_forms/src/locales/validators_localizations.dart';

import 'forms_localizations.dart';

class FormsLocaleEn extends LnFormsLocalizations {
  const FormsLocaleEn() : super("en");

  @override
  String get okButton => "OK";

  @override
  String get editButton => "Edit";

  @override
  String get resetButton => "Reset";

  @override
  String get restoreButton => "Restore";

  @override
  String get saveButton => "Save";

  @override
  String get cancelButton => "Cancel";

  @override
  String get confirmButton => "Confirm";

  @override
  String get youHaveAlreadyAddedThis => "You Have already added this";

  @override
  String get clickHereForSelectAnImage => "Click here for select an image";

  @override
  String areYouSureYouWantToX(String action) =>
      "Are you sure you want to $action";

  @override
  String clearX(String s) => "Clear $s";

  @override
  String get formFields => "Form fields";

  @override
  String get restoreChanges => "Restore changes";
}

class ValidatorsLocaleEn extends LnValidatorsLocalizations {
  const ValidatorsLocaleEn() : super("en");

  @override
  String get theField => "The field";

  @override
  String fieldCanNotBeEmpty(String field) => "$field can not be empty";

  @override
  String fieldRequired(String field) => "$field required";

  @override
  String fieldShouldBeAccepted(String field) => "$field should be accepted";

  @override
  String fieldMustBeLengthCharactersLong(String field, int length) =>
      "$field must be $length characters long";

  @override
  String fieldMustBeAtLeastLengthCharactersLong(String field, int length) =>
      "$field must be at least $length characters long";

  @override
  String fieldMustBeAtMostLengthCharactersLong(String field, int length) =>
      "$field must be at most $length characters long";

  @override
  String fieldAndTheOtherFieldMustBeDifferent(
          String field, String otherField) =>
      "$field and $otherField must be different";

  @override
  String fieldsDontMatch(String fields) => "$fields don't match";

  @override
  String get mobileNumberIsInvalid => "Mobile number is invalid";

  @override
  String get emailFormatIsInvalid => "Email format is invalid";
}
