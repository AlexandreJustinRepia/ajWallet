import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AttachmentService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from [source] and copies it to the app's documents directory.
  /// Returns the local path of the stored image.
  static Future<String?> pickAndStoreImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image == null) return null;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String attachmentsDirPath = path.join(appDir.path, 'attachments');
      final Directory attachmentsDir = Directory(attachmentsDirPath);

      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final String localPath = path.join(attachmentsDirPath, fileName);

      final File localFile = await File(image.path).copy(localPath);
      return localFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Deletes a local attachment file.
  static Future<void> deleteAttachment(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore errors during deletion
    }
  }
}
