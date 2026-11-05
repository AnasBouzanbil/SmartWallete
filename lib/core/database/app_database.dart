import 'package:drift/drift.dart';

import 'enums.dart';
import 'tables.dart';
import 'uuid.dart';

export 'enums.dart';
export 'settings_keys.dart';

part 'app_database.g.dart';

/// The app's local SQLite database (schema v2).
@DriftDatabase(
  tables: <Type>[
    Accounts,
    Categories,
    Transactions,
    Debts,
    DebtPayments,
    Budgets,
    RecurringRules,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass a file executor in production and `NativeDatabase.memory()` in tests.
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDefaults();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // v1 was never wired to any UI, so it holds no user data.
            await customStatement('DROP TABLE IF EXISTS transactions');
            await customStatement('DROP TABLE IF EXISTS debts');
            await m.createAll();
            await _seedDefaults();
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          final List<Account> existing =
              await (select(accounts)..limit(1)).get();
          if (existing.isEmpty) {
            await _insertDefaultAccount();
          }
        },
      );

  Future<void> _insertDefaultAccount() {
    return into(accounts).insert(
      AccountsCompanion.insert(
        name: 'Cash',
        type: AccountType.cash,
        colorValue: 0xFFD9F36A,
      ),
    );
  }

  Future<void> _seedDefaults() async {
    await _insertDefaultAccount();
    await _seedCategories();
  }

  Future<void> _seedCategories() async {
    CategoriesCompanion c(
      String name,
      CategoryKind kind,
      String icon,
      int color,
      int order,
    ) =>
        CategoriesCompanion.insert(
          name: name,
          kind: kind,
          iconKey: icon,
          colorValue: color,
          sortOrder: Value<int>(order),
        );

    await batch((Batch b) {
      b.insertAll(categories, <CategoriesCompanion>[
        c('Food', CategoryKind.expense, 'food', 0xFFE0FE44, 0),
        c('Transport', CategoryKind.expense, 'transport', 0xFF8FB4CF, 1),
        c('Bills', CategoryKind.expense, 'bills', 0xFFF2A08C, 2),
        c('Fun', CategoryKind.expense, 'fun', 0xFF7EE08A, 3),
        c('Health', CategoryKind.expense, 'health', 0xFFC9A7F0, 4),
        c('Other', CategoryKind.expense, 'other', 0xFFA3AD97, 5),
        c('Salary', CategoryKind.income, 'salary', 0xFF7EE08A, 0),
        c('Other income', CategoryKind.income, 'other', 0xFFA3AD97, 1),
      ]);
    });
  }
}
