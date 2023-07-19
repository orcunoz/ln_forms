import 'package:ln_core/ln_core.dart';
import 'package:logger/logger.dart';

class FormLog {
  static final Logger _logger = Logger(
      printer: HybridPrinter(LnPrinter(),
          error: PrettyPrinter(noBoxingByDefault: true)));

  static d(String fieldType, String functionName, int fieldLevel,
      {required String? fieldName}) {
    assert(fieldLevel >= 1);
    String? fieldNameLine = fieldName?.pascalCase.toFixed(20, fillChar: "_");
    fieldNameLine = fieldNameLine == null ? '' : "[$fieldNameLine]";
    String fieldTypeStr =
        fieldLevel == 1 ? fieldType.toFixed(8, fillChar: "_") : fieldType;
    String levelLine = "".toFixed((fieldLevel - 1) * 3, fillChar: "=");
    String messageLine = "$levelLine$fieldTypeStr"
        "$fieldNameLine.$functionName";
    _logger.d(messageLine);
  }

  static e(dynamic errorOrMessage, {StackTrace? stackTrace}) {
    Error? error = errorOrMessage is Error ? errorOrMessage : null;

    _logger.e(errorOrMessage, error);
    if (stackTrace != null) {
      _logger.e(errorOrMessage, error, stackTrace);
    }
  }

  static wtf(dynamic message) {
    _logger.wtf("WTF!.$message");
  }
}
