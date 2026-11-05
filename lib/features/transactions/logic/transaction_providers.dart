import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/transaction_repository.dart';

final Provider<TransactionRepository> transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final StreamProvider<List<TransactionWithCategory>> recentTransactionsProvider =
    StreamProvider<List<TransactionWithCategory>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchRecent();
});

final StreamProvider<List<TransactionWithCategory>> allTransactionsProvider =
    StreamProvider<List<TransactionWithCategory>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAll();
});

final monthlyTotalsProvider =
    StreamProvider.family<MonthlyTotals, DateTime>((ref, DateTime month) {
  return ref.watch(transactionRepositoryProvider).watchTotalsInMonth(month);
});

final StreamProvider<int> netMinorProvider = StreamProvider<int>((ref) {
  return ref.watch(transactionRepositoryProvider).watchNetMinor();
});

final FutureProvider<Account> defaultAccountProvider =
    FutureProvider<Account>((ref) async {
  final AppDatabase db = ref.watch(databaseProvider);
  final Account? account = await (db.select(db.accounts)
        ..orderBy(<OrderingTerm Function($AccountsTable)>[
          ($AccountsTable a) => OrderingTerm.asc(a.id),
        ])
        ..limit(1))
      .getSingleOrNull();
  if (account == null) {
    throw StateError('No account available.');
  }
  return account;
});

final StreamProvider<List<Category>> categoriesProvider =
    StreamProvider<List<Category>>((ref) {
  final AppDatabase db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..where(($CategoriesTable c) => c.isArchived.equals(false))
        ..orderBy(<OrderingTerm Function($CategoriesTable)>[
          ($CategoriesTable c) => OrderingTerm.asc(c.sortOrder),
        ]))
      .watch();
});
