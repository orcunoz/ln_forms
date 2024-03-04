import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/src/localization/forms_localizations.dart';

typedef ValidatorFunction<T> = String? Function(T?);

class Validator<T> {
  final String? fieldName;
  final List<ValidatorFunction<T>> _functions = <ValidatorFunction<T>>[];
  Validator([this.fieldName]);

  String get nnFieldName => fieldName ?? LnFormsLocalizations.current.theField;

  String _nnStr(dynamic dyn) => dyn?.toString() ?? '';

  Validator<T> test(ValidatorFunction<T> func) => this.._functions.add(func);

  Validator<T> get required => test((val) => _nnStr(val).isEmpty
      ? LnFormsLocalizations.current.fieldRequired(nnFieldName).sentenceCase
      : null);

  Validator<T> get shouldBeAccepted => test((val) => val == null || val == false
      ? LnFormsLocalizations.current
          .fieldShouldBeAccepted(nnFieldName)
          .sentenceCase
      : null);

  Validator<T> get canNotBeEmpty => test((val) => _nnStr(val).isEmpty
      ? LnFormsLocalizations.current
          .fieldCanNotBeEmpty(nnFieldName)
          .sentenceCase
      : null);

  Validator<T> minLength(int length) =>
      test((val) => _nnStr(val).length < length
          ? LnFormsLocalizations.current
              .fieldMustBeLengthCharactersLong(nnFieldName, length)
              .sentenceCase
          : null);

  Validator<T> maxLength(int length) =>
      test((val) => _nnStr(val).length > length
          ? LnFormsLocalizations.current
              .fieldMustBeAtLeastLengthCharactersLong(nnFieldName, length)
              .sentenceCase
          : null);

  Validator<T> shouldBeDifferent(
          T? Function() otherValue, String otherFieldName) =>
      test((val) => val == otherValue()
          ? LnFormsLocalizations.current
              .fieldAndTheOtherFieldMustBeDifferent(nnFieldName, otherFieldName)
              .sentenceCase
          : null);

  Validator<T> shouldMatchWith(T? Function() otherValue, String fieldNames) =>
      test((val) => val != otherValue()
          ? LnFormsLocalizations.current
              .fieldsDontMatch(fieldNames)
              .sentenceCase
          : null);

  Validator<T> get email => regExp(
      RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9\-\_]+(\.[a-zA-Z]+)*$"),
      LnFormsLocalizations.current.emailFormatIsInvalid);

  Validator<T> regExp(RegExp regExp, String errorMessage) => test((val) =>
      val == null || regExp.hasMatch(val.toString()) ? null : errorMessage);

  String? build(T? value) {
    for (var func in _functions) {
      var errorText = func(value);
      if (errorText != null) return errorText;
    }
    return null;
  }
}
