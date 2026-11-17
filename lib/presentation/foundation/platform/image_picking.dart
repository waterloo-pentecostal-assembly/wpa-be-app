import 'package:image_picker/image_picker.dart';

import '../../../domain/common/media_upload.dart';

/// Lets the user pick an image from the gallery. Works on every platform
/// (reads bytes; no file-system access).
Future<ImageData?> pickImageFromGallery({ImagePicker? picker}) async {
  final file = await (picker ?? ImagePicker()).pickImage(
    source: ImageSource.gallery,
  );
  if (file == null) return null;
  return ImageData(
    bytes: await file.readAsBytes(),
    fileName: file.name,
    mimeType: file.mimeType,
  );
}
