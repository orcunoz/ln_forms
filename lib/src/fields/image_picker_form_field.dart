import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ln_core/ln_core.dart';
import 'package:universal_io/io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ln_forms/ln_forms.dart';

class ImagePickerFormField extends LnFormField<String> {
  final ImageSource source;

  ImagePickerFormField({
    super.key,
    super.initialValue,
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
          builder: (LnFormFieldState<String> field) {
            final state = field as ImagePickerFormFieldState;
            final theme = Theme.of(state.context);
            final inputBorder = theme.inputDecorationTheme.enabledBorder
                    is OutlineInputBorder
                ? theme.inputDecorationTheme.enabledBorder as OutlineInputBorder
                : null;
            return ConstrainedBox(
              constraints: field.scopedState.readOnly
                  ? const BoxConstraints(maxHeight: 300)
                  : const BoxConstraints.expand(height: 300),
              child: ClipRRect(
                borderRadius:
                    inputBorder?.borderRadius ?? BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: field.value != null
                    ? field.buildImageWidget(field.context, field.value!)
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

class ImagePickerFormFieldState extends LnFormFieldState<String>
    with FutureFormField<String> {
  @override
  ImagePickerFormField get widget => super.widget as ImagePickerFormField;

  String? _lastSavedImageUrl;
  Uint8List? _decodedImage;

  @override
  InputDecoration get effectiveDecoration => super.effectiveDecoration.copyWith(
        floatingLabelBehavior: FloatingLabelBehavior.always,
      );

  @override
  Future<String?> toFuture() async {
    final pickedFile = await ImagePicker().pickImage(source: widget.source);

    if (pickedFile != null) {
      return await File(pickedFile.path).toBase64();
    }

    return null;
  }

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
          color: Theme.of(context).colorScheme.error.withOpacity(0.5),
        );
      },
    );
  }
}
