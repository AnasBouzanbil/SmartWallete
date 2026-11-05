import 'package:drift/drift.dart';

import 'enums.dart';
import 'tables.dart';

export 'enums.dart';

part 'app_database.g.dart';

/// The app's local SQLite database. Two tables only:
/// [Transactions] for income/expense, [Debts] for money lent/owed.
@DriftDatabase(tables: [Transactions, Debts])
class AppDatabase extends _$AppDatabase {
  /// Build the database on the given executor.
  ///
  /// Pass a native/file executor in production and
  /// `NativeDatabase.memory()` in tests.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
