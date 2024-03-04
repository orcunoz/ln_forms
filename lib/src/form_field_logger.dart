import '../ln_forms.dart';
import 'utilities/logger.dart';

mixin FieldLoggerMixin {
  String? get loggerFieldName;

  void log(String functionName) {
    if (kLoggingEnabled && loggerFieldName != null) {
      final fieldType = "$runtimeType".split("FormField").first;
      final fieldName = loggerFieldName;

      FormLog.d(fieldType, functionName, 1, fieldName: fieldName);
    }
  }
}
