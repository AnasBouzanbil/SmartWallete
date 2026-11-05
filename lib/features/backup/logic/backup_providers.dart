import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/backup_file_service.dart';
import '../data/backup_service.dart';
import '../data/receipt_backup_store.dart';

final Provider<ReceiptBackupStore> receiptBackupStoreProvider =
    Provider<ReceiptBackupStore>((ref) {
  return const LocalReceiptBackupStore();
});

final Provider<BackupService> backupServiceProvider =
    Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    ref.watch(receiptBackupStoreProvider),
  );
});

final Provider<BackupFileService> backupFileServiceProvider =
    Provider<BackupFileService>((ref) {
  return const BackupFileService();
});
