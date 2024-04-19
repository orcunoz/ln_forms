import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ln_forms/ln_forms.dart';

class ImagePickerField extends LnSimpleFutureField<String?> {
  ImagePickerField({
    super.key,
    super.value,
    super.controller,
    super.onChanged,
    super.onSaved,
    super.focusNode,
    super.validator,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.restoreable,
    super.decoration,
    this.source = ImageSource.gallery,
  }) : super(
          useFocusNode: true,
          style: null,
          builder: (field, computedState) {
            field as ImagePickerFieldState;
            final hintColor = field.computedDecoration?.hintStyle?.color ??
                field.theme.hintColor;
            final borderRadius =
                field.computedDecoration?.enabledBorder?.borderRadius ??
                    BorderRadius.zero;

            return ConstrainedBox(
              constraints: computedState.readOnly
                  ? const BoxConstraints(maxHeight: 300)
                  : const BoxConstraints.expand(height: 300),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: field.value != null
                    ? field.buildImageWidget(field.context, field.value!)
                    : Icon(
                        Icons.image_search_rounded,
                        size: 72,
                        color: hintColor.withOpacity(.3),
                      ),
              ),
            );
          },
          emptyValue: null,
          onTrigger: _onTrigger,
        );

  final ImageSource source;

  @override
  LnSimpleFutureFieldState<String?> createState() {
    return ImagePickerFieldState();
  }

  static Future<String?> _onTrigger(
      LnSimpleFutureFieldState<String?> state) async {
    final field = state.widget as ImagePickerField;
    final pickedFile = await ImagePicker().pickImage(source: field.source);

    if (pickedFile != null) {
      return await File(pickedFile.path).toBase64();
    }

    return null;
  }
}

class ImagePickerFieldState extends LnSimpleFutureFieldState<String?> {
  @override
  ImagePickerField get widget => super.widget as ImagePickerField;

  String? _lastSavedImageUrl;
  Uint8List? _decodedImage;

  @override
  InputDecoration? get computedDecoration => super.computedDecoration?.copyWith(
        floatingLabelBehavior: FloatingLabelBehavior.always,
      );

  Widget buildImageWidget(BuildContext context, String imageUrl) {
    ImageProvider<Object> imageProvider;
    if (imageUrl.startsWith("http")) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      if (_lastSavedImageUrl != imageUrl) {
        _decodedImage = base64Decode(imageUrl);
        _lastSavedImageUrl = imageUrl;
      }
      imageProvider = MemoryImage(_decodedImage!);
    }

    return Image(
      image: imageProvider,
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
          color: theme.colorScheme.error.withOpacity(0.5),
        );
      },
    );
  }

  @override
  FieldController<String?> createController(String? value) {
    return NullableFieldController<String>(null);
  }
}
