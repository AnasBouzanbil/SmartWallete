import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> addAccount() => db.into(db.accounts).insert(
        AccountsCompanion.insert(
          name: 'Cash',
          type: AccountType.cash,
          colorValue: 0xFFE0FE44,
        ),
      );

  Future<int> firstExpenseCategory() async {
    final List<Category> all = await db.select(db.categories).get();
    return all.firstWhere((Category c) => c.kind == CategoryKind.expense).id;
  }

  test('seeds default categories on first create', () async {
    final List<Category> all = await db.select(db.categories).get();
    expect(all.length, 8);
    expect(all.where((Category c) => c.kind == CategoryKind.income).length, 2);
  });

  test('stores money as integers and fills uuid/timestamps', () async {
    final int account = await addAccount();
    final int category = await firstExpenseCategory();
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account,
            categoryId: category,
            type: TransactionType.expense,
            amountMinor: 4250,
            date: DateTime(2026, 11, 4),
          ),
        );
    final Transaction t = await db.select(db.transactions).getSingle();
    expect(t.amountMinor, 4250);
    expect(t.uuid.length, 36);
    expect(t.deletedAt, isNull);
  });

  test('rejects zero or negative amounts', () async {
    final int account = await addAccount();
    final int category = await firstExpenseCategory();
    expect(
      () => db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: account,
              categoryId: category,
              type: TransactionType.expense,
              amountMinor: 0,
              date: DateTime(2026, 11, 4),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('enforces foreign keys', () async {
    final int category = await firstExpenseCategory();
    expect(
      () => db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: 999,
              categoryId: category,
              type: TransactionType.expense,
              amountMinor: 100,
              date: DateTime(2026, 11, 4),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('debt supports partial payments', () async {
    final int debtId = await db.into(db.debts).insert(
          DebtsCompanion.insert(
            person: 'Sam',
            direction: DebtDirection.lent,
            principalMinor: 10000,
          ),
        );
    await db.into(db.debtPayments).insert(
          DebtPaymentsCompanion.insert(
            debtId: debtId,
            amountMinor: 4000,
            paidAt: DateTime(2026, 11, 5),
          ),
        );
    final List<DebtPayment> payments = await db.select(db.debtPayments).get();
    expect(payments.fold<int>(0, (int s, DebtPayment p) => s + p.amountMinor), 4000);
  });
}
