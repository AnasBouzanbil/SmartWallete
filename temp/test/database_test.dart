import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts and reads back a transaction and a debt', () async {
    final DateTime txDate = DateTime(2026, 1, 15, 10, 30);
    final DateTime dueDate = DateTime(2026, 2, 1);

    final int txId = await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            type: TransactionType.expense,
            amount: 42.75,
            person: const Value('Supermarket'),
            note: const Value('Weekly groceries'),
            category: 'Food',
            date: txDate,
            imagePath: const Value('/images/receipt_1.jpg'),
          ),
        );

    final int debtId = await db.into(db.debts).insert(
          DebtsCompanion.insert(
            person: 'Ali',
            amount: 500,
            direction: DebtDirection.lent,
            dueDate: Value(dueDate),
            note: const Value('Lunch money'),
            createdAt: DateTime(2026, 1, 10),
          ),
        );

    expect(txId, greaterThan(0));
    expect(debtId, greaterThan(0));

    final Transaction tx =
        await (db.select(db.transactions)..where((t) => t.id.equals(txId)))
            .getSingle();

    expect(tx.type, TransactionType.expense);
    expect(tx.amount, 42.75);
    expect(tx.person, 'Supermarket');
    expect(tx.note, 'Weekly groceries');
    expect(tx.category, 'Food');
    expect(tx.date, txDate);
    expect(tx.imagePath, '/images/receipt_1.jpg');

    final Debt debt =
        await (db.select(db.debts)..where((d) => d.id.equals(debtId)))
            .getSingle();

    expect(debt.person, 'Ali');
    expect(debt.amount, 500);
    expect(debt.direction, DebtDirection.lent);
    expect(debt.dueDate, dueDate);
    expect(debt.note, 'Lunch money');
    expect(debt.isSettled, isFalse);
  });

  test('rejects a non-positive amount', () async {
    expect(
      () => db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              type: TransactionType.income,
              amount: 0,
              category: 'Other',
              date: DateTime(2026, 1, 1),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
