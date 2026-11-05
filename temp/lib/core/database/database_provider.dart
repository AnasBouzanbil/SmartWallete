import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'database_connection.dart';

/// Provides the single [AppDatabase] instance for the whole app.
///
/// The database is opened lazily on first read and closed automatically
/// when the provider is disposed.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase db = AppDatabase(openAppDatabaseConnection());
  ref.onDispose(db.close);
  return db;
});
