import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the on-device SQLite database file.
///
/// The file lives in the app documents directory so it is private to the
/// app and removed when the app is uninstalled.
LazyDatabase openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'smart_wallet.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
