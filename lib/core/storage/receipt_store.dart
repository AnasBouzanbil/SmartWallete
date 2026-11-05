import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/uuid.dart';

class ReceiptStore {
  const ReceiptStore._();

  static const String folderName = 'receipts';

  static final RegExp _relativePath =
      RegExp(r'^receipts/[A-Za-z0-9._-]+$');

  static bool isValidRelativePath(String path) {
    return _relativePath.hasMatch(path) && !path.contains('..');
  }

  static Future<Directory> directory() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, folderName));
  }

  static Future<String> save(XFile file) async {
    final Directory receipts = await directory();
    if (!await receipts.exists()) {
      await receipts.create(recursive: true);
    }

    final String extension = p.extension(file.path);
    final String name = '${newUuid()}$extension';
    await File(file.path).copy(p.join(receipts.path, name));
    return p.join(folderName, name);
  }

  /// Resolves a relative [imagePath] (as stored in the DB) to an absolute path.
  static Future<String> absolutePath(String imagePath) async {
    final Directory documents = await getApplicationDocumentsDirectory();
    return p.join(documents.path, imagePath);
  }

  /// Deletes the receipt file if it exists. Missing files are ignored.
  static Future<void> delete(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }
    final String path = await absolutePath(imagePath);
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
