import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'backup_models.dart';

class BackupFileService {
  const BackupFileService();

  Future<Uint8List?> pickJson() async {
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        dialogTitle: 'Select a Smart Wallet backup',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
      );
      if (file == null) {
        return null;
      }
      return file.readAsBytes();
    } catch (_) {
      throw const BackupException('Could not open the file picker.');
    }
  }

  Future<bool> saveJson({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final Uri? uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
        dialogTitle: 'Save Smart Wallet backup',
      );
      return uri != null;
    } catch (_) {
      throw const BackupException('Could not save the backup file.');
    }
  }
}
