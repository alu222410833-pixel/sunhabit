import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sunhabit/core/theme/app_colors.dart';

class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage({
    ImageSource source = ImageSource.gallery,
    bool crop = true,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int compressQuality = 85,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );
      if (picked == null) return null;

      if (!crop) return picked.path;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: compressQuality,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar imagen',
            toolbarColor: AppColors.surfaceElevated,
            toolbarWidgetColor: AppColors.neonGreen,
            statusBarLight: true,
            backgroundColor: AppColors.backgroundDark,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Ajustar imagen',
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      return await _persistToAppDir(cropped?.path ?? picked.path);
    } catch (_) {
      return null;
    }
  }

  /// Copia la imagen al directorio de documentos de la app.
  ///
  /// `image_picker`/`image_cropper` devuelven archivos en caché, que Android
  /// puede borrar en cualquier momento (y lo hace en Huawei/Honor/Xiaomi).
  /// Sin esta copia, las rutas guardadas dejan de existir y la UI muestra
  /// huecos vacíos.
  Future<String?> _persistToAppDir(String path) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      if (path.startsWith(docsDir.path)) return path;
      final imagesDir = Directory('${docsDir.path}/images')
        ..createSync(recursive: true);
      final extension = path.contains('.') ? path.split('.').last : 'jpg';
      final fileName = 'img_${DateTime.now().microsecondsSinceEpoch}.$extension';
      final persisted = await File(path).copy('${imagesDir.path}/$fileName');
      return persisted.path;
    } catch (_) {
      return path;
    }
  }

  Future<String?> pickFromGallery() => pickImage(source: ImageSource.gallery);

  Future<String?> pickFromCamera() => pickImage(source: ImageSource.camera);
}
