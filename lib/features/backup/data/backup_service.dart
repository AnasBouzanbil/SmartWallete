import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'backup_models.dart';
import 'receipt_backup_store.dart';

class BackupService {
  BackupService(this._db, this._receipts);

  final AppDatabase _db;
  final ReceiptBackupStore _receipts;

  Future<BackupDocument> export({
    required BackupProfile profile,
    bool includePhotos = true,
  }) async {
    final List<Account> accounts = await _activeAccounts();
    final List<Category> categories = await _activeCategories();
    final List<Transaction> transactions = await _activeTransactions();
    final List<Debt> debts = await _activeDebts();
    final List<DebtPayment> debtPayments = await _activeDebtPayments();
    final List<Budget> budgets = await _activeBudgets();
    final List<RecurringRule> recurringRules = await _activeRecurringRules();
    final List<AppSetting> settings = await _settings();

    final Map<String, Uint8List> receipts = <String, Uint8List>{};
    final List<Transaction> exportedTransactions = <Transaction>[];
    for (final Transaction transaction in transactions) {
      final String? imagePath = transaction.imagePath;
      if (!includePhotos || imagePath == null || imagePath.isEmpty) {
        exportedTransactions.add(
          transaction.copyWith(imagePath: const Value<String?>(null)),
        );
        continue;
      }

      Uint8List? bytes = receipts[imagePath];
      bytes ??= await _receipts.read(imagePath);
      if (bytes == null) {
        exportedTransactions.add(
          transaction.copyWith(imagePath: const Value<String?>(null)),
        );
      } else {
        receipts[imagePath] = bytes;
        exportedTransactions.add(transaction);
      }
    }

    return BackupDocument(
      exportedAt: DateTime.now(),
      profile: profile,
      accounts: accounts,
      categories: categories,
      transactions: exportedTransactions,
      debts: debts,
      debtPayments: debtPayments,
      budgets: budgets,
      recurringRules: recurringRules,
      settings: settings,
      receipts: receipts,
    );
  }

  Future<BackupImportResult> import(BackupDocument document) async {
    final Map<String, Uint8List> receipts = <String, Uint8List>{};
    final List<Transaction> transactions = <Transaction>[];
    for (final Transaction transaction in document.transactions) {
      final String? imagePath = transaction.imagePath;
      final Uint8List? bytes =
          imagePath == null ? null : document.receipts[imagePath];
      if (imagePath != null && bytes != null) {
        receipts[imagePath] = bytes;
        transactions.add(transaction);
      } else {
        transactions.add(
          transaction.copyWith(imagePath: const Value<String?>(null)),
        );
      }
    }

    final StagedReceipts staged = await _receipts.stage(receipts);
    try {
      await _db.transaction(() async {
        await _db.delete(_db.debtPayments).go();
        await _db.delete(_db.transactions).go();
        await _db.delete(_db.budgets).go();
        await _db.delete(_db.recurringRules).go();
        await _db.delete(_db.debts).go();
        await _db.delete(_db.categories).go();
        await _db.delete(_db.accounts).go();
        await _db.delete(_db.appSettings).go();

        for (final Account account in document.accounts) {
          await _db.into(_db.accounts).insert(account.toCompanion(false));
        }
        for (final Category category in document.categories) {
          await _db.into(_db.categories).insert(category.toCompanion(false));
        }
        for (final RecurringRule rule in document.recurringRules) {
          await _db
              .into(_db.recurringRules)
              .insert(rule.toCompanion(false));
        }
        for (final Transaction transaction in transactions) {
          await _db
              .into(_db.transactions)
              .insert(transaction.toCompanion(false));
        }
        for (final Debt debt in document.debts) {
          await _db.into(_db.debts).insert(debt.toCompanion(false));
        }
        for (final DebtPayment payment in document.debtPayments) {
          await _db
              .into(_db.debtPayments)
              .insert(payment.toCompanion(false));
        }
        for (final Budget budget in document.budgets) {
          await _db.into(_db.budgets).insert(budget.toCompanion(false));
        }
        for (final AppSetting setting in document.settings) {
          await _db
              .into(_db.appSettings)
              .insert(setting.toCompanion(false));
        }
      });
    } catch (_) {
      await staged.discard();
      rethrow;
    }

    try {
      await staged.commit();
      return const BackupImportResult(receiptsRestored: true);
    } catch (_) {
      return const BackupImportResult(receiptsRestored: false);
    }
  }

  Future<List<Account>> _activeAccounts() async {
    final List<Account> rows = await (_db.select(_db.accounts)
          ..where(($AccountsTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((Account a, Account b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<Category>> _activeCategories() async {
    final List<Category> rows = await (_db.select(_db.categories)
          ..where(($CategoriesTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((Category a, Category b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<Transaction>> _activeTransactions() async {
    final List<Transaction> rows = await (_db.select(_db.transactions)
          ..where(($TransactionsTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((Transaction a, Transaction b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<Debt>> _activeDebts() async {
    final List<Debt> rows = await (_db.select(_db.debts)
          ..where(($DebtsTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((Debt a, Debt b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<DebtPayment>> _activeDebtPayments() async {
    final List<DebtPayment> rows = await (_db.select(_db.debtPayments)
          ..where(($DebtPaymentsTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((DebtPayment a, DebtPayment b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<Budget>> _activeBudgets() async {
    final List<Budget> rows = await (_db.select(_db.budgets)
          ..where(($BudgetsTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((Budget a, Budget b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<RecurringRule>> _activeRecurringRules() async {
    final List<RecurringRule> rows = await (_db.select(_db.recurringRules)
          ..where(($RecurringRulesTable t) => t.deletedAt.isNull()))
        .get();
    rows.sort((RecurringRule a, RecurringRule b) => a.id.compareTo(b.id));
    return rows;
  }

  Future<List<AppSetting>> _settings() async {
    final List<AppSetting> rows = await _db.select(_db.appSettings).get();
    rows.sort((AppSetting a, AppSetting b) => a.key.compareTo(b.key));
    return rows;
  }
}
