import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class TransactionWithCategory {
  const TransactionWithCategory({
    required this.transaction,
    required this.category,
  });

  final Transaction transaction;
  final Category category;
}

class MonthlyTotals {
  const MonthlyTotals({required this.incomeMinor, required this.expenseMinor});

  static const MonthlyTotals zero =
      MonthlyTotals(incomeMinor: 0, expenseMinor: 0);

  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;
}

(DateTime, DateTime) monthRange(DateTime month) {
  final DateTime start = DateTime(month.year, month.month);
  final DateTime end = DateTime(month.year, month.month + 1);
  return (start, end);
}

class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _withCategory() {
    return _db.select(_db.transactions).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
    ])
      ..where(_db.transactions.deletedAt.isNull());
  }

  Stream<List<TransactionWithCategory>> watchRecent({int limit = 3}) {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _withCategory()
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_db.transactions.date),
            OrderingTerm.desc(_db.transactions.createdAt),
          ])
          ..limit(limit);

    return query.watch().map(
          (List<TypedResult> rows) => rows.map(_mapRow).toList(),
        );
  }

  Stream<List<TransactionWithCategory>> watchAll() {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _withCategory()
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_db.transactions.date),
            OrderingTerm.desc(_db.transactions.createdAt),
          ]);

    return query.watch().map(
          (List<TypedResult> rows) => rows.map(_mapRow).toList(),
        );
  }

  Stream<List<TransactionWithCategory>> watchExpensesInRange(
    DateTime start,
    DateTime end,
  ) {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _withCategory()
          ..where(
            _db.transactions.type.equalsValue(TransactionType.expense) &
                _db.transactions.date.isBiggerOrEqualValue(start) &
                _db.transactions.date.isSmallerThanValue(end),
          )
          ..orderBy(<OrderingTerm>[
            OrderingTerm.desc(_db.transactions.date),
          ]);

    return query.watch().map(
          (List<TypedResult> rows) => rows.map(_mapRow).toList(),
        );
  }

  Stream<MonthlyTotals> watchTotalsInMonth(DateTime month) {
    final (DateTime start, DateTime end) = monthRange(month);
    final Selectable<QueryRow> query = _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_minor ELSE 0 END), 0)
          AS income_minor,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_minor ELSE 0 END), 0)
          AS expense_minor
      FROM transactions
      WHERE deleted_at IS NULL AND date >= ? AND date < ?
      ''',
      variables: <Variable>[
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
      readsFrom: <ResultSetImplementation>{_db.transactions},
    );

    return query.watchSingle().map(
          (QueryRow row) => MonthlyTotals(
            incomeMinor: row.read<int>('income_minor'),
            expenseMinor: row.read<int>('expense_minor'),
          ),
        );
  }

  Stream<int> watchNetMinor() {
    final Selectable<QueryRow> query = _db.customSelect(
      '''
      SELECT COALESCE(SUM(
        CASE WHEN type = 'income' THEN amount_minor ELSE -amount_minor END
      ), 0) AS net_minor
      FROM transactions
      WHERE deleted_at IS NULL
      ''',
      readsFrom: <ResultSetImplementation>{_db.transactions},
    );

    return query.watchSingle().map(
          (QueryRow row) => row.read<int>('net_minor'),
        );
  }

  Future<int> add({
    required TransactionType type,
    required int amountMinor,
    required int categoryId,
    required int accountId,
    DateTime? date,
    String? person,
    String? note,
    String? imagePath,
  }) {
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: accountId,
            categoryId: categoryId,
            type: type,
            amountMinor: amountMinor,
            date: date ?? DateTime.now(),
            person: Value<String?>(_emptyToNull(person)),
            note: Value<String?>(_emptyToNull(note)),
            imagePath: Value<String?>(_emptyToNull(imagePath)),
          ),
        );
  }

  Future<TransactionWithCategory?> getById(int id) async {
    final JoinedSelectStatement<HasResultSet, dynamic> query = _withCategory()
      ..where(_db.transactions.id.equals(id));
    final TypedResult? row = await query.getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  Future<void> update({
    required int id,
    required TransactionType type,
    required int amountMinor,
    required int categoryId,
    required DateTime date,
    String? person,
    String? note,
    String? imagePath,
  }) {
    return (_db.update(_db.transactions)
          ..where(($TransactionsTable t) => t.id.equals(id)))
        .write(
      TransactionsCompanion(
        type: Value<TransactionType>(type),
        amountMinor: Value<int>(amountMinor),
        categoryId: Value<int>(categoryId),
        date: Value<DateTime>(date),
        person: Value<String?>(_emptyToNull(person)),
        note: Value<String?>(_emptyToNull(note)),
        imagePath: Value<String?>(_emptyToNull(imagePath)),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  Future<void> delete(int id) {
    return (_db.update(_db.transactions)
          ..where(($TransactionsTable t) => t.id.equals(id)))
        .write(
      TransactionsCompanion(
        deletedAt: Value<DateTime>(DateTime.now()),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  TransactionWithCategory _mapRow(TypedResult row) {
    return TransactionWithCategory(
      transaction: row.readTable(_db.transactions),
      category: row.readTable(_db.categories),
    );
  }

  static String? _emptyToNull(String? value) {
    final String? trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
