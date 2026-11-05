import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/features/transactions/data/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });

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

  Future<int> firstIncomeCategory() async {
    final List<Category> all = await db.select(db.categories).get();
    return all.firstWhere((Category c) => c.kind == CategoryKind.income).id;
  }

  test('update changes fields and sets updatedAt', () async {
    final int account = await addAccount();
    final int expense = await firstExpenseCategory();
    final int income = await firstIncomeCategory();
    final int id = await repo.add(
      type: TransactionType.expense,
      amountMinor: 2500,
      categoryId: expense,
      accountId: account,
      person: 'Ali',
      note: 'Lunch',
    );

    expect(await repo.getById(id), isNotNull);

    final DateTime watermark =
        DateTime.now().subtract(const Duration(seconds: 2));
    await repo.update(
      id: id,
      type: TransactionType.income,
      amountMinor: 5000,
      categoryId: income,
      date: DateTime(2026, 1, 15),
      person: 'Sara',
      note: 'Refund',
      imagePath: 'receipts/demo.jpg',
    );

    final TransactionWithCategory? after = await repo.getById(id);
    expect(after, isNotNull);
    expect(after!.transaction.type, TransactionType.income);
    expect(after.transaction.amountMinor, 5000);
    expect(after.transaction.categoryId, income);
    expect(after.transaction.person, 'Sara');
    expect(after.transaction.note, 'Refund');
    expect(after.transaction.imagePath, 'receipts/demo.jpg');
    expect(after.transaction.date, DateTime(2026, 1, 15));
    expect(after.transaction.updatedAt.isAfter(watermark), isTrue);
  });

  test('delete soft-deletes and hides from watchAll', () async {
    final int account = await addAccount();
    final int category = await firstExpenseCategory();
    final int id = await repo.add(
      type: TransactionType.expense,
      amountMinor: 1000,
      categoryId: category,
      accountId: account,
    );

    expect(await repo.getById(id), isNotNull);

    await repo.delete(id);

    expect(await repo.getById(id), isNull);

    final List<TransactionWithCategory> all = await repo.watchAll().first;
    expect(all.where((TransactionWithCategory i) => i.transaction.id == id),
        isEmpty);

    final Transaction row = await (db.select(db.transactions)
          ..where(($TransactionsTable t) => t.id.equals(id)))
        .getSingle();
    expect(row.deletedAt, isNotNull);
  });
}
