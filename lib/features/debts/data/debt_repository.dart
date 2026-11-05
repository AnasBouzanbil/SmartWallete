import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class DebtSummary {
  const DebtSummary({required this.debt, required this.paidMinor});

  final Debt debt;
  final int paidMinor;

  int get outstandingMinor => max(0, debt.principalMinor - paidMinor);

  bool get isSettled => outstandingMinor == 0;
}

class DebtOverview {
  const DebtOverview({
    required this.youOweMinor,
    required this.owedToYouMinor,
    required this.youOweCount,
    required this.owedToYouCount,
    this.nearestDueDate,
  });

  static const DebtOverview empty = DebtOverview(
    youOweMinor: 0,
    owedToYouMinor: 0,
    youOweCount: 0,
    owedToYouCount: 0,
  );

  final int youOweMinor;
  final int owedToYouMinor;
  final int youOweCount;
  final int owedToYouCount;
  final DateTime? nearestDueDate;

  factory DebtOverview.from(List<DebtSummary> debts) {
    int youOwe = 0;
    int owedToYou = 0;
    int youOweCount = 0;
    int owedToYouCount = 0;
    DateTime? nearest;

    for (final DebtSummary item in debts) {
      if (item.isSettled) {
        continue;
      }
      if (item.debt.direction == DebtDirection.owed) {
        youOwe += item.outstandingMinor;
        youOweCount++;
      } else {
        owedToYou += item.outstandingMinor;
        owedToYouCount++;
      }
      final DateTime? due = item.debt.dueDate;
      if (due != null && (nearest == null || due.isBefore(nearest))) {
        nearest = due;
      }
    }

    return DebtOverview(
      youOweMinor: youOwe,
      owedToYouMinor: owedToYou,
      youOweCount: youOweCount,
      owedToYouCount: owedToYouCount,
      nearestDueDate: nearest,
    );
  }
}

class DebtPaymentException implements Exception {
  const DebtPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DebtRepository {
  DebtRepository(this._db);

  final AppDatabase _db;

  Stream<List<DebtSummary>> watchAll() {
    final Selectable<QueryRow> query = _db.customSelect(
      '''
      SELECT d.*, COALESCE(SUM(p.amount_minor), 0) AS paid_minor
      FROM debts d
      LEFT JOIN debt_payments p
        ON p.debt_id = d.id AND p.deleted_at IS NULL
      WHERE d.deleted_at IS NULL
      GROUP BY d.id
      ORDER BY d.due_date IS NULL, d.due_date, d.created_at DESC
      ''',
      readsFrom: <ResultSetImplementation>{
        _db.debts,
        _db.debtPayments,
      },
    );

    return query.watch().map(
          (List<QueryRow> rows) => rows.map(_mapSummary).toList(),
        );
  }

  Future<DebtSummary?> getById(int id) async {
    final Selectable<QueryRow> query = _db.customSelect(
      '''
      SELECT d.*, COALESCE(SUM(p.amount_minor), 0) AS paid_minor
      FROM debts d
      LEFT JOIN debt_payments p
        ON p.debt_id = d.id AND p.deleted_at IS NULL
      WHERE d.deleted_at IS NULL AND d.id = ?
      GROUP BY d.id
      ''',
      variables: <Variable>[Variable<int>(id)],
      readsFrom: <ResultSetImplementation>{
        _db.debts,
        _db.debtPayments,
      },
    );
    final QueryRow? row = await query.getSingleOrNull();
    return row == null ? null : _mapSummary(row);
  }

  Stream<List<DebtPayment>> watchPayments(int debtId) {
    final SimpleSelectStatement<$DebtPaymentsTable, DebtPayment> query =
        _db.select(_db.debtPayments)
          ..where(
            ($DebtPaymentsTable p) =>
                p.debtId.equals(debtId) & p.deletedAt.isNull(),
          )
          ..orderBy(<OrderingTerm Function($DebtPaymentsTable)>[
            ($DebtPaymentsTable p) => OrderingTerm.desc(p.paidAt),
            ($DebtPaymentsTable p) => OrderingTerm.desc(p.createdAt),
          ]);
    return query.watch();
  }

  Future<int> add({
    required String person,
    required DebtDirection direction,
    required int principalMinor,
    DateTime? dueDate,
    String? note,
  }) {
    final String trimmed = person.trim();
    if (trimmed.isEmpty) {
      throw const DebtPaymentException('Enter a person name.');
    }
    if (principalMinor <= 0) {
      throw const DebtPaymentException('Enter an amount.');
    }
    return _db.into(_db.debts).insert(
          DebtsCompanion.insert(
            person: trimmed,
            direction: direction,
            principalMinor: principalMinor,
            dueDate: Value<DateTime?>(dueDate),
            note: Value<String?>(_emptyToNull(note)),
          ),
        );
  }

  Future<void> update({
    required int id,
    required String person,
    required DebtDirection direction,
    required int principalMinor,
    DateTime? dueDate,
    String? note,
  }) async {
    final String trimmed = person.trim();
    if (trimmed.isEmpty) {
      throw const DebtPaymentException('Enter a person name.');
    }
    if (principalMinor <= 0) {
      throw const DebtPaymentException('Enter an amount.');
    }

    final DebtSummary? current = await getById(id);
    if (current == null) {
      throw const DebtPaymentException('Debt not found.');
    }
    if (principalMinor < current.paidMinor) {
      throw DebtPaymentException(
        'Principal cannot be less than already paid '
        '(${current.paidMinor}).',
      );
    }

    await (_db.update(_db.debts)..where(($DebtsTable d) => d.id.equals(id)))
        .write(
      DebtsCompanion(
        person: Value<String>(trimmed),
        direction: Value<DebtDirection>(direction),
        principalMinor: Value<int>(principalMinor),
        dueDate: Value<DateTime?>(dueDate),
        note: Value<String?>(_emptyToNull(note)),
        updatedAt: Value<DateTime>(DateTime.now()),
      ),
    );
  }

  Future<void> delete(int id) async {
    final DateTime now = DateTime.now();
    await (_db.update(_db.debts)..where(($DebtsTable d) => d.id.equals(id)))
        .write(
      DebtsCompanion(
        deletedAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
      ),
    );
    await (_db.update(_db.debtPayments)
          ..where(($DebtPaymentsTable p) => p.debtId.equals(id)))
        .write(
      DebtPaymentsCompanion(
        deletedAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  Future<int> addPayment({
    required int debtId,
    required int amountMinor,
    DateTime? paidAt,
    String? note,
  }) async {
    final DebtSummary? summary = await getById(debtId);
    if (summary == null) {
      throw const DebtPaymentException('Debt not found.');
    }
    if (summary.isSettled) {
      throw const DebtPaymentException('This debt is already settled.');
    }
    if (amountMinor <= 0) {
      throw const DebtPaymentException('Enter an amount.');
    }
    if (amountMinor > summary.outstandingMinor) {
      throw const DebtPaymentException(
        'Payment cannot be more than the amount left.',
      );
    }

    return _db.into(_db.debtPayments).insert(
          DebtPaymentsCompanion.insert(
            debtId: debtId,
            amountMinor: amountMinor,
            paidAt: paidAt ?? DateTime.now(),
            note: Value<String?>(_emptyToNull(note)),
          ),
        );
  }

  Future<void> deletePayment(int id) {
    final DateTime now = DateTime.now();
    return (_db.update(_db.debtPayments)
          ..where(($DebtPaymentsTable p) => p.id.equals(id)))
        .write(
      DebtPaymentsCompanion(
        deletedAt: Value<DateTime>(now),
        updatedAt: Value<DateTime>(now),
      ),
    );
  }

  DebtSummary _mapSummary(QueryRow row) {
    final Debt debt = Debt(
      uuid: row.read<String>('uuid'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
      deletedAt: row.readNullable<DateTime>('deleted_at'),
      id: row.read<int>('id'),
      person: row.read<String>('person'),
      direction: DebtDirection.values.byName(row.read<String>('direction')),
      principalMinor: row.read<int>('principal_minor'),
      dueDate: row.readNullable<DateTime>('due_date'),
      note: row.readNullable<String>('note'),
      accountId: row.readNullable<int>('account_id'),
    );
    return DebtSummary(
      debt: debt,
      paidMinor: row.read<int>('paid_minor'),
    );
  }

  static String? _emptyToNull(String? value) {
    final String? trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
