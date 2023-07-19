import 'package:ln_core/ln_core.dart';

import 'locale_en.dart';
import 'locale_tr.dart';

/*

  "customErrorSomethingWentWrong": "Something went wrong",
  "customErrorNoResultsFound": "No results found",
  "customErrorUnauthorizedAccess": "Unauthorized access",
  "htmlEditorNotSupportedWarning": "You can only edit this field on mobile and web platforms.",

  "formSave": "Save",
  "formEdit": "Edit",
  "formCancel": "Cancel",
  "formCreateNewX": "Create New {item}",




    "customErrorSomethingWentWrong": "Bir şeyler ters gitti",
    "customErrorNoResultsFound": "Sonuç bulunamadı",
    "customErrorUnauthorizedAccess": "Yetkisiz erişim",
    "htmlEditorNotSupportedWarning": "Bu alanı sadece mobil ve web platformlarında düzenleyebilirsiniz.",

*/

final formLocalizations = LnLocalizationScope<FormsLocale>([
  LocaleEn(),
  LocaleTr(),
]);

abstract class FormsLocale extends LnLocale {
  const FormsLocale(super.languageCode);

  String get okButton;
  String get saveButton;
  String get editButton;
  String get cancelButton;
  String get restoreButton;
  String get resetButton;
  String get confirmButton;
  String get youHaveAlreadyAddedThis;
  String get clickHereForSelectAnImage;
  String areYouSureYouWantToX(String action);
  String clearX(String s);
  String get restoreChanges;
  String get formFields;
}
