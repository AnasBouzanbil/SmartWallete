import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

abstract interface class WalletResetService {
  Future<void> reset();
}

class LocalWalletResetService implements WalletResetService {
  LocalWalletResetService(this._database);

  final AppDatabase _database;

  @override
  Future<void> reset() async {
    await _database.close();

    final Directory dir = await getApplicationDocumentsDirectory();
    const List<String> names = <String>[
      'smart_wallet.sqlite',
      'smart_wallet.sqlite-wal',
      'smart_wallet.sqlite-shm',
    ];
    for (final String name in names) {
      final File file = File(p.join(dir.path, name));
      if (await file.exists()) {
        await file.delete();
      }
    }

    final Directory receipts = Directory(p.join(dir.path, 'receipts'));
    if (await receipts.exists()) {
      await receipts.delete(recursive: true);
    }
  }
}

final Provider<WalletResetService> walletResetServiceProvider =
    Provider<WalletResetService>((ref) {
  return LocalWalletResetService(ref.read(databaseProvider));
});
