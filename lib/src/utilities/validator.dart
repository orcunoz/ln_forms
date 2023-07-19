import 'package:ln_core/ln_core.dart';
import 'package:ln_forms/src/locales/validator_localizations.dart';

typedef ValidatorFunction<T> = String? Function(T?);

class Validator<T> {
  final String? fieldName;
  final List<ValidatorFunction<T>> _functions = <ValidatorFunction<T>>[];
  Validator([this.fieldName]);

  String get nnFieldName =>
      fieldName ?? validatorLocalizations.current.theField;

  String _nnStr(dynamic dyn) => dyn?.toString() ?? '';

  Validator<T> test(ValidatorFunction<T> func) => this.._functions.add(func);

  Validator<T> get required => test((val) => _nnStr(val).isEmpty
      ? validatorLocalizations.current.fieldRequired(nnFieldName).sentenceCase
      : null);

  Validator<T> get shouldBeAccepted => test((val) => val == null || val == false
      ? validatorLocalizations.current
          .fieldShouldBeAccepted(nnFieldName)
          .sentenceCase
      : null);

  Validator<T> get canNotBeEmpty => test((val) => _nnStr(val).isEmpty
      ? validatorLocalizations.current
          .fieldCanNotBeEmpty(nnFieldName)
          .sentenceCase
      : null);

  Validator<T> minLength(int length) =>
      test((val) => _nnStr(val).length < length
          ? validatorLocalizations.current
              .fieldMustBeLengthCharactersLong(nnFieldName, length)
              .sentenceCase
          : null);

  Validator<T> maxLength(int length) =>
      test((val) => _nnStr(val).length > length
          ? validatorLocalizations.current
              .fieldMustBeAtLeastLengthCharactersLong(nnFieldName, length)
              .sentenceCase
          : null);

  Validator<T> shouldBeDifferent(
          T? Function() otherValue, String otherFieldName) =>
      test((val) => val == otherValue()
          ? validatorLocalizations.current
              .fieldAndTheOtherFieldMustBeDifferent(nnFieldName, otherFieldName)
              .sentenceCase
          : null);

  Validator<T> shouldMatchWith(T? Function() otherValue, String fieldNames) =>
      test((val) => val != otherValue()
          ? validatorLocalizations.current
              .fieldsDontMatch(fieldNames)
              .sentenceCase
          : null);

  Validator<T> get email => regExp(
      RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9\-\_]+(\.[a-zA-Z]+)*$"),
      validatorLocalizations.current.emailFormatIsInvalid);

  Validator<T> regExp(RegExp regExp, String errorMessage) => test((val) =>
      val == null || regExp.hasMatch(val.toString()) ? null : errorMessage);

  String? call(T? value) {
    for (var func in _functions) {
      var errorText = func(value);
      if (errorText != null) return errorText;
    }
    return null;
  }

  static bool isEmptyValue(dynamic value) =>
      value == null ||
      (value is String && value.isEmpty) ||
      (value is Iterable && value.isEmpty);
}