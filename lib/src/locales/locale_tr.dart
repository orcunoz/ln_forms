import 'form_localizations.dart';
import 'validator_localizations.dart';

class LocaleTr extends FormsLocale {
  const LocaleTr() : super("tr");

  @override
  String get okButton => "Tamam";

  @override
  String get cancelButton => "İptal";

  @override
  String get editButton => "Düzenle";

  @override
  String get resetButton => "Sıfırla";

  @override
  String get restoreButton => "Geri Al";

  @override
  String get saveButton => "Kaydet";

  @override
  String get confirmButton => "Onayla";

  @override
  String get youHaveAlreadyAddedThis => "Bunu zaten eklediniz!";

  @override
  String get clickHereForSelectAnImage =>
      "Galeriden resim seçmek için tıklayınız";

  @override
  String areYouSureYouWantToX(String action) =>
      "$action istediğinize emin misiniz?";

  @override
  String clearX(String s) => "$s 'ni temizlemek";

  @override
  String get formFields => "Form alanları";

  @override
  String get restoreChanges => "Değişiklikleri geri almak";
}

class ValidatorLocaleTr extends ValidatorLocale {
  const ValidatorLocaleTr() : super("tr");

  @override
  String get theField => "Bu alan";

  @override
  String fieldCanNotBeEmpty(String field) => "$field boş olamaz";

  @override
  String fieldRequired(String field) => "$field zorunludur";

  @override
  String fieldShouldBeAccepted(String field) => "$field kabul edilmedilir";

  @override
  String fieldMustBeLengthCharactersLong(String field, int length) =>
      "$field $length karakter uzunluğunda olmalıdır";

  @override
  String fieldMustBeAtLeastLengthCharactersLong(String field, int length) =>
      "$field en az $length karakter uzunluğunda olmalıdır";

  @override
  String fieldMustBeAtMostLengthCharactersLong(String field, int length) =>
      "$field en çok $length karakter uzunluğunda olmalıdır";

  @override
  String fieldsDontMatch(String fields) => "$fields eşleşmiyor";

  @override
  String fieldAndTheOtherFieldMustBeDifferent(
          String field, String otherField) =>
      "$field ile $otherField birbirinden farklı olmalıdır";

  @override
  String get emailFormatIsInvalid => "E-posta adresi formatı geçersiz";

  @override
  String get mobileNumberIsInvalid => "Telefon numarası geçersiz";
}
