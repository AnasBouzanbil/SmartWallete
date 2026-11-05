import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/uuid.dart';
import '../../../core/storage/receipt_store.dart';
import 'backup_models.dart';

abstract interface class ReceiptBackupStore {
  Future<Uint8List?> read(String relativePath);

  Future<StagedReceipts> stage(Map<String, Uint8List> files);
}

abstract interface class StagedReceipts {
  Future<void> commit();

  Future<void> discard();
}

class LocalReceiptBackupStore implements ReceiptBackupStore {
  const LocalReceiptBackupStore();

  @override
  Future<Uint8List?> read(String relativePath) async {
    if (!ReceiptStore.isValidRelativePath(relativePath)) {
      throw BackupException('Invalid receipt path: $relativePath');
    }
    final File file = File(await ReceiptStore.absolutePath(relativePath));
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<StagedReceipts> stage(Map<String, Uint8List> files) async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory target =
        Directory(p.join(documents.path, ReceiptStore.folderName));
    final Directory staged = Directory(
      p.join(
        documents.path,
        '${ReceiptStore.folderName}.staged.${newUuid()}',
      ),
    );
    await staged.create(recursive: true);

    try {
      for (final MapEntry<String, Uint8List> entry in files.entries) {
        if (!ReceiptStore.isValidRelativePath(entry.key)) {
          throw BackupException('Invalid receipt path: ${entry.key}');
        }
        final File file = File(p.join(staged.path, p.basename(entry.key)));
        await file.writeAsBytes(entry.value, flush: true);
      }
    } catch (_) {
      await _deleteIfExists(staged);
      rethrow;
    }

    return _LocalStagedReceipts(staged: staged, target: target);
  }
}

class _LocalStagedReceipts implements StagedReceipts {
  _LocalStagedReceipts({required this.staged, required this.target});

  final Directory staged;
  final Directory target;

  @override
  Future<void> commit() async {
    if (!await staged.exists()) {
      return;
    }

    final Directory backup = Directory(
      p.join(
        target.parent.path,
        '${ReceiptStore.folderName}.old.${newUuid()}',
      ),
    );
    bool movedOld = false;

    try {
      if (await target.exists()) {
        await target.rename(backup.path);
        movedOld = true;
      }
      await staged.rename(target.path);
      if (movedOld) {
        await _deleteIfExists(backup);
      }
    } catch (_) {
      if (movedOld && !await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      await discard();
      rethrow;
    }
  }

  @override
  Future<void> discard() => _deleteIfExists(staged);
}

Future<void> _deleteIfExists(Directory directory) async {
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}
