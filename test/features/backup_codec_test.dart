import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/features/backup/data/backup_codec.dart';
import 'package:smartwallete/features/backup/data/backup_models.dart';

void main() {
  final DateTime t = DateTime(2026, 11, 5, 10, 30);

  BackupDocument document() {
    return BackupDocument(
      exportedAt: t,
      profile: const BackupProfile(
        name: 'Sara',
        startingBalanceMinor: 100000,
      ),
      accounts: <Account>[
        Account(
          uuid: 'account-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          name: 'Cash',
          type: AccountType.cash,
          openingBalanceMinor: 0,
          colorValue: 0xFFD9F36A,
          sortOrder: 0,
          isArchived: false,
        ),
      ],
      categories: <Category>[
        Category(
          uuid: 'category-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          name: 'Food',
          kind: CategoryKind.expense,
          iconKey: 'food',
          colorValue: 0xFFE0FE44,
          sortOrder: 0,
          isArchived: false,
        ),
      ],
      transactions: <Transaction>[
        Transaction(
          uuid: 'transaction-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amountMinor: 1234,
          note: 'Lunch',
          date: t,
          imagePath: 'receipts/photo.jpg',
        ),
      ],
      debts: <Debt>[
        Debt(
          uuid: 'debt-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          person: 'Sam',
          direction: DebtDirection.lent,
          principalMinor: 5000,
          dueDate: t,
          accountId: 1,
        ),
      ],
      debtPayments: <DebtPayment>[
        DebtPayment(
          uuid: 'payment-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          debtId: 1,
          amountMinor: 1000,
          paidAt: t,
          accountId: 1,
        ),
      ],
      budgets: <Budget>[
        Budget(
          uuid: 'budget-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          categoryId: 1,
          limitMinor: 10000,
        ),
      ],
      recurringRules: <RecurringRule>[
        RecurringRule(
          uuid: 'rule-uuid',
          createdAt: t,
          updatedAt: t,
          id: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amountMinor: 1000,
          frequency: RecurrenceFrequency.monthly,
          startDate: t,
          nextDueDate: t,
          isActive: true,
        ),
      ],
      settings: <AppSetting>[
        const AppSetting(key: 'currency_code', value: 'MAD'),
      ],
      receipts: <String, Uint8List>{
        'receipts/photo.jpg': Uint8List.fromList(<int>[1, 2, 3]),
      },
    );
  }

  group('BackupCodec', () {
    test('round-trips all tables and receipts', () {
      final BackupDocument decoded =
          BackupCodec.decode(BackupCodec.encode(document()));

      expect(decoded.profile.name, 'Sara');
      expect(decoded.profile.startingBalanceMinor, 100000);
      expect(decoded.accounts.single.name, 'Cash');
      expect(decoded.categories.single.kind, CategoryKind.expense);
      expect(decoded.transactions.single.amountMinor, 1234);
      expect(decoded.transactions.single.imagePath, 'receipts/photo.jpg');
      expect(decoded.debts.single.person, 'Sam');
      expect(decoded.debtPayments.single.amountMinor, 1000);
      expect(decoded.budgets.single.limitMinor, 10000);
      expect(decoded.recurringRules.single.frequency,
          RecurrenceFrequency.monthly);
      expect(decoded.settings.single.value, 'MAD');
      expect(decoded.receipts['receipts/photo.jpg'], <int>[1, 2, 3]);
    });

    test('rejects invalid JSON', () {
      expect(
        () => BackupCodec.decode('not json'),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a different format', () {
      final Map<String, dynamic> json = _json(document());
      json['format'] = 'another-app';
      expect(
        () => BackupCodec.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a newer backup version', () {
      final Map<String, dynamic> json = _json(document());
      json['version'] = 99;
      expect(
        () => BackupCodec.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a backup with no account', () {
      final Map<String, dynamic> json = _json(document());
      json['accounts'] = <dynamic>[];
      expect(
        () => BackupCodec.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects broken foreign keys', () {
      final Map<String, dynamic> json = _json(document());
      final List<dynamic> transactions =
          json['transactions'] as List<dynamic>;
      (transactions.single as Map<String, dynamic>)['accountId'] = 999;
      expect(
        () => BackupCodec.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects unsafe receipt paths', () {
      final Map<String, dynamic> json = _json(document());
      json['receipts'] = <String, String>{
        '../escape.jpg': base64Encode(<int>[1, 2, 3]),
      };
      expect(
        () => BackupCodec.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects duplicate ids', () {
      final Map<String, dynamic> json = _json(document());
      final List<dynamic> accounts = json['accounts'] as List<dynamic>;
      accounts.add(Map<String, dynamic>.from(
        accounts.single as Map<String, dynamic>,
      ));
      expect(
        () => BackupCodec.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      );
    });
  });
}

Map<String, dynamic> _json(BackupDocument document) {
  return jsonDecode(BackupCodec.encode(document)) as Map<String, dynamic>;
}
