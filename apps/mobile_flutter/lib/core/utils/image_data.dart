import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

Future<String?> pickImageDataUrl() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 72,
    maxWidth: 1280,
  );

  if (file == null) {
    return null;
  }

  final bytes = await file.readAsBytes();
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

Uint8List? imageBytesFromDataUrl(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final comma = value.indexOf(',');
  final payload = comma == -1 ? value : value.substring(comma + 1);

  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}
