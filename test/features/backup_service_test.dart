import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/features/backup/data/backup_models.dart';
import 'package:smartwallete/features/backup/data/backup_service.dart';
import 'package:smartwallete/features/backup/data/receipt_backup_store.dart';

void main() {
  late AppDatabase db;
  late FakeReceiptBackupStore receipts;
  late BackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    receipts = FakeReceiptBackupStore();
    service = BackupService(db, receipts);
  });

  tearDown(() => db.close());

  Future<void> seed() async {
    final Account account = (await db.select(db.accounts).get()).first;
    final Category category = (await db.select(db.categories).get())
        .firstWhere((Category c) => c.kind == CategoryKind.expense);
    final DateTime date = DateTime(2026, 11, 5);

    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: account.id,
            categoryId: category.id,
            type: TransactionType.expense,
            amountMinor: 1234,
            note: const Value<String?>('Lunch'),
            date: date,
            imagePath: const Value<String?>('receipts/photo.jpg'),
          ),
        );
    final int debtId = await db.into(db.debts).insert(
          DebtsCompanion.insert(
            person: 'Sam',
            direction: DebtDirection.lent,
            principalMinor: 5000,
            accountId: Value<int?>(account.id),
          ),
        );
    await db.into(db.debtPayments).insert(
          DebtPaymentsCompanion.insert(
            debtId: debtId,
            amountMinor: 1000,
            paidAt: date,
            accountId: Value<int?>(account.id),
          ),
        );
    await db.into(db.budgets).insert(
          BudgetsCompanion.insert(
            categoryId: category.id,
            limitMinor: 10000,
          ),
        );
    await db.into(db.recurringRules).insert(
          RecurringRulesCompanion.insert(
            accountId: account.id,
            categoryId: category.id,
            type: TransactionType.expense,
            amountMinor: 2000,
            frequency: RecurrenceFrequency.monthly,
            startDate: date,
            nextDueDate: date,
          ),
        );
    await db.into(db.appSettings).insert(
          AppSettingsCompanion.insert(
            key: 'currency_code',
            value: 'MAD',
          ),
        );

    receipts.files['receipts/photo.jpg'] =
        Uint8List.fromList(<int>[1, 2, 3]);
  }

  const BackupProfile profile = BackupProfile(
    name: 'Sara',
    startingBalanceMinor: 100000,
  );

  group('BackupService.export', () {
    test('includes active rows and receipt photos', () async {
      await seed();

      final BackupDocument document = await service.export(
        profile: profile,
        includePhotos: true,
      );

      expect(document.profile.name, 'Sara');
      expect(document.accounts, hasLength(1));
      expect(document.categories, hasLength(8));
      expect(document.transactions, hasLength(1));
      expect(document.debts, hasLength(1));
      expect(document.debtPayments, hasLength(1));
      expect(document.budgets, hasLength(1));
      expect(document.recurringRules, hasLength(1));
      expect(document.settings, hasLength(1));
      expect(document.receipts.keys, contains('receipts/photo.jpg'));
      expect(
        document.transactions.single.imagePath,
        'receipts/photo.jpg',
      );
    });

    test('omits receipt photos when disabled', () async {
      await seed();

      final BackupDocument document = await service.export(
        profile: profile,
        includePhotos: false,
      );

      expect(document.receipts, isEmpty);
      expect(document.transactions.single.imagePath, isNull);
    });

    test('clears a missing receipt path', () async {
      await seed();
      receipts.files.clear();

      final BackupDocument document = await service.export(
        profile: profile,
        includePhotos: true,
      );

      expect(document.receipts, isEmpty);
      expect(document.transactions.single.imagePath, isNull);
    });
  });

  group('BackupService.import', () {
    test('replaces all data and restores receipts', () async {
      await seed();
      final BackupDocument document = await service.export(
        profile: profile,
        includePhotos: true,
      );

      final AppDatabase fresh = AppDatabase(NativeDatabase.memory());
      final FakeReceiptBackupStore freshReceipts = FakeReceiptBackupStore();
      final BackupService freshService = BackupService(fresh, freshReceipts);
      addTearDown(fresh.close);

      final BackupImportResult result = await freshService.import(document);

      expect(result.receiptsRestored, isTrue);
      expect(freshReceipts.files['receipts/photo.jpg'], <int>[1, 2, 3]);
      expect(freshReceipts.staged.single.committed, isTrue);

      final List<Account> accounts = await fresh.select(fresh.accounts).get();
      final List<Category> categories =
          await fresh.select(fresh.categories).get();
      final List<Transaction> transactions =
          await fresh.select(fresh.transactions).get();
      final List<Debt> debts = await fresh.select(fresh.debts).get();
      final List<DebtPayment> payments =
          await fresh.select(fresh.debtPayments).get();
      final List<Budget> budgets = await fresh.select(fresh.budgets).get();
      final List<RecurringRule> rules =
          await fresh.select(fresh.recurringRules).get();
      final List<AppSetting> settings =
          await fresh.select(fresh.appSettings).get();

      expect(accounts, hasLength(document.accounts.length));
      expect(accounts.single.id, document.accounts.single.id);
      expect(categories, hasLength(document.categories.length));
      expect(transactions.single.id, document.transactions.single.id);
      expect(transactions.single.imagePath, 'receipts/photo.jpg');
      expect(debts.single.person, 'Sam');
      expect(payments.single.amountMinor, 1000);
      expect(budgets.single.limitMinor, 10000);
      expect(rules.single.frequency, RecurrenceFrequency.monthly);
      expect(settings.single.value, 'MAD');
    });

    test('rolls back the database and discards staged receipts on failure',
        () async {
      await seed();
      final BackupDocument document = await service.export(
        profile: profile,
        includePhotos: true,
      );
      final BackupDocument broken = BackupDocument(
        exportedAt: document.exportedAt,
        profile: document.profile,
        accounts: document.accounts,
        categories: document.categories,
        transactions: <Transaction>[
          document.transactions.single.copyWith(accountId: 999),
        ],
        debts: document.debts,
        debtPayments: document.debtPayments,
        budgets: document.budgets,
        recurringRules: document.recurringRules,
        settings: document.settings,
        receipts: document.receipts,
      );

      final AppDatabase fresh = AppDatabase(NativeDatabase.memory());
      final FakeReceiptBackupStore freshReceipts = FakeReceiptBackupStore();
      final BackupService freshService = BackupService(fresh, freshReceipts);
      addTearDown(fresh.close);

      await expectLater(
        freshService.import(broken),
        throwsA(anything),
      );

      expect(freshReceipts.staged.single.discarded, isTrue);
      expect(freshReceipts.staged.single.committed, isFalse);
      expect(await fresh.select(fresh.accounts).get(), hasLength(1));
      expect(await fresh.select(fresh.transactions).get(), isEmpty);
    });
  });
}

class FakeReceiptBackupStore implements ReceiptBackupStore {
  final Map<String, Uint8List> files = <String, Uint8List>{};
  final List<FakeStagedReceipts> staged = <FakeStagedReceipts>[];

  @override
  Future<Uint8List?> read(String relativePath) async => files[relativePath];

  @override
  Future<StagedReceipts> stage(Map<String, Uint8List> files) async {
    final Map<String, Uint8List> copy =
        Map<String, Uint8List>.from(files);
    final FakeStagedReceipts result = FakeStagedReceipts(
      onCommit: () {
        this.files
          ..clear()
          ..addAll(copy);
      },
    );
    staged.add(result);
    return result;
  }
}

class FakeStagedReceipts implements StagedReceipts {
  FakeStagedReceipts({required this.onCommit});

  final void Function() onCommit;
  bool committed = false;
  bool discarded = false;

  @override
  Future<void> commit() async {
    committed = true;
    onCommit();
  }

  @override
  Future<void> discard() async {
    discarded = true;
  }
}
