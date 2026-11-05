import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/features/debts/data/debt_repository.dart';

void main() {
  late AppDatabase db;
  late DebtRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DebtRepository(db);
  });

  tearDown(() => db.close());

  test('add and getById return a summary with zero paid', () async {
    final int id = await repo.add(
      person: 'Ali',
      direction: DebtDirection.owed,
      principalMinor: 5000,
      note: 'Lunch',
    );

    final DebtSummary? summary = await repo.getById(id);
    expect(summary, isNotNull);
    expect(summary!.debt.person, 'Ali');
    expect(summary.debt.direction, DebtDirection.owed);
    expect(summary.debt.principalMinor, 5000);
    expect(summary.debt.note, 'Lunch');
    expect(summary.paidMinor, 0);
    expect(summary.outstandingMinor, 5000);
    expect(summary.isSettled, isFalse);
  });

  test('update changes fields and sets updatedAt', () async {
    final int id = await repo.add(
      person: 'Ali',
      direction: DebtDirection.owed,
      principalMinor: 5000,
    );
    final DateTime watermark =
        DateTime.now().subtract(const Duration(seconds: 2));

    await repo.update(
      id: id,
      person: 'Sara',
      direction: DebtDirection.lent,
      principalMinor: 8000,
      dueDate: DateTime(2026, 12, 1),
      note: 'Rent',
    );

    final DebtSummary? after = await repo.getById(id);
    expect(after, isNotNull);
    expect(after!.debt.person, 'Sara');
    expect(after.debt.direction, DebtDirection.lent);
    expect(after.debt.principalMinor, 8000);
    expect(after.debt.dueDate, DateTime(2026, 12, 1));
    expect(after.debt.note, 'Rent');
    expect(after.debt.updatedAt.isAfter(watermark), isTrue);
  });

  test('delete soft-deletes debt and hides from watchAll', () async {
    final int id = await repo.add(
      person: 'Ali',
      direction: DebtDirection.owed,
      principalMinor: 2000,
    );
    await repo.addPayment(debtId: id, amountMinor: 500);

    await repo.delete(id);

    expect(await repo.getById(id), isNull);
    final List<DebtSummary> all = await repo.watchAll().first;
    expect(all.where((DebtSummary s) => s.debt.id == id), isEmpty);

    final Debt debt = await (db.select(db.debts)
          ..where(($DebtsTable d) => d.id.equals(id)))
        .getSingle();
    expect(debt.deletedAt, isNotNull);

    final List<DebtPayment> payments = await (db.select(db.debtPayments)
          ..where(($DebtPaymentsTable p) => p.debtId.equals(id)))
        .get();
    expect(payments, isNotEmpty);
    expect(payments.every((DebtPayment p) => p.deletedAt != null), isTrue);
  });

  test('addPayment rejects overpayment and settles when full', () async {
    final int id = await repo.add(
      person: 'Ali',
      direction: DebtDirection.lent,
      principalMinor: 1000,
    );

    expect(
      () => repo.addPayment(debtId: id, amountMinor: 1500),
      throwsA(isA<DebtPaymentException>()),
    );

    await repo.addPayment(debtId: id, amountMinor: 400);
    DebtSummary? summary = await repo.getById(id);
    expect(summary!.paidMinor, 400);
    expect(summary.outstandingMinor, 600);
    expect(summary.isSettled, isFalse);

    await repo.addPayment(debtId: id, amountMinor: 600);
    summary = await repo.getById(id);
    expect(summary!.isSettled, isTrue);
    expect(summary.outstandingMinor, 0);

    expect(
      () => repo.addPayment(debtId: id, amountMinor: 1),
      throwsA(isA<DebtPaymentException>()),
    );
  });

  test('deletePayment restores outstanding amount', () async {
    final int id = await repo.add(
      person: 'Ali',
      direction: DebtDirection.owed,
      principalMinor: 3000,
    );
    final int paymentId =
        await repo.addPayment(debtId: id, amountMinor: 1000);

    expect((await repo.getById(id))!.outstandingMinor, 2000);

    await repo.deletePayment(paymentId);

    final DebtSummary? summary = await repo.getById(id);
    expect(summary!.paidMinor, 0);
    expect(summary.outstandingMinor, 3000);

    final List<DebtPayment> visible =
        await repo.watchPayments(id).first;
    expect(visible, isEmpty);
  });

  test('update rejects principal below already paid', () async {
    final int id = await repo.add(
      person: 'Ali',
      direction: DebtDirection.owed,
      principalMinor: 5000,
    );
    await repo.addPayment(debtId: id, amountMinor: 2000);

    expect(
      () => repo.update(
        id: id,
        person: 'Ali',
        direction: DebtDirection.owed,
        principalMinor: 1000,
      ),
      throwsA(isA<DebtPaymentException>()),
    );
  });
}
