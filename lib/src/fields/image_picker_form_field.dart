import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:universal_io/io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ln_forms/ln_forms.dart';

class ImagePickerFormField extends InputFormField<String> {
  final ImageSource source;

  ImagePickerFormField({
    super.key,
    super.initialValue,
    super.onChanged,
    super.onSaved,
    super.focusNode,
    super.validate,
    super.readOnly,
    super.enabled,
    super.decoration,
    this.source = ImageSource.gallery,
  }) : super(
          useFocusNode: true,
          clearable: false,
          restoreable: false,
          builder: (InputFormFieldState<String> field) {
            final state = field as ImagePickerFormFieldState;
            final theme = Theme.of(state.context);
            final inputBorder = theme.inputDecorationTheme.enabledBorder
                    is OutlineInputBorder
                ? theme.inputDecorationTheme.enabledBorder as OutlineInputBorder
                : null;
            return ConstrainedBox(
              constraints: state.widget.readOnly
                  ? const BoxConstraints(maxHeight: 300)
                  : const BoxConstraints.expand(height: 300),
              child: ClipRRect(
                borderRadius:
                    inputBorder?.borderRadius ?? BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: field.value != null
                    ? Image(
                        image: NetworkImage(field.value!),
                        alignment: Alignment.center,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          return loadingProgress == null
                              ? child
                              : const CircularProgressIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            size: 72,
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.5),
                          );
                        },
                      )
                    : Icon(
                        Icons.image_search_rounded,
                        size: 72,
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
              ),
            );
          },
        );

  @override
  ImagePickerFormFieldState createState() {
    return ImagePickerFormFieldState();
  }
}

class ImagePickerFormFieldState extends InputFormFieldState<String>
    with FutureFormField<String> {
  @override
  ImagePickerFormField get widget => super.widget as ImagePickerFormField;

  @override
  InputDecoration get effectiveDecoration => super.effectiveDecoration.copyWith(
        floatingLabelBehavior: FloatingLabelBehavior.always,
      );

  @override
  Future<String?> toFuture() {
    return ImagePicker().pickImage(source: widget.source).then(
        (pickedFile) async =>
            pickedFile == null ? null : await File(pickedFile.path).toBase64());
  }

  Widget buildImageWidget(BuildContext context, String? imageUrl) {
    return Image.network(
      imageUrl ?? "",
      alignment: Alignment.center,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        return loadingProgress == null
            ? child
            : Center(child: const CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.image_not_supported_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.error.withOpacity(0.5),
        );
      },
    );
  }
}
