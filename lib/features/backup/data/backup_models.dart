import 'dart:typed_data';

import '../../../core/database/app_database.dart';

abstract final class BackupFormat {
  static const String name = 'smartwallet-backup';
  static const int version = 1;
  static const int appSchemaVersion = 2;
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupProfile {
  const BackupProfile({
    required this.name,
    required this.startingBalanceMinor,
  });

  final String name;
  final int startingBalanceMinor;
}

class BackupImportResult {
  const BackupImportResult({required this.receiptsRestored});

  final bool receiptsRestored;
}

class BackupDocument {
  const BackupDocument({
    required this.exportedAt,
    required this.profile,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.debts,
    required this.debtPayments,
    required this.budgets,
    required this.recurringRules,
    required this.settings,
    required this.receipts,
  });

  final DateTime exportedAt;
  final BackupProfile profile;
  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<Debt> debts;
  final List<DebtPayment> debtPayments;
  final List<Budget> budgets;
  final List<RecurringRule> recurringRules;
  final List<AppSetting> settings;
  final Map<String, Uint8List> receipts;

  String get summary {
    final int payments = debtPayments.length;
    final int photos = receipts.length;
    return '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}, '
        '${transactions.length} '
        '${transactions.length == 1 ? 'transaction' : 'transactions'}, '
        '${debts.length} ${debts.length == 1 ? 'debt' : 'debts'}'
        '${payments == 0 ? '' : ', $payments '
            '${payments == 1 ? 'payment' : 'payments'}'}'
        '${photos == 0 ? '' : ', $photos '
            '${photos == 1 ? 'photo' : 'photos'}'}';
  }
}
