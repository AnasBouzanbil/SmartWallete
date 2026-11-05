import 'dart:convert';
import 'dart:typed_data';

import '../../../core/database/app_database.dart';
import 'backup_models.dart';

abstract final class BackupCodec {
  static final RegExp _receiptPath = RegExp(r'^receipts/[A-Za-z0-9._-]+$');

  static String encode(BackupDocument document) {
    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'format': BackupFormat.name,
      'version': BackupFormat.version,
      'appSchemaVersion': BackupFormat.appSchemaVersion,
      'exportedAt': _iso(document.exportedAt),
      'profile': <String, dynamic>{
        'name': document.profile.name,
        'startingBalanceMinor': document.profile.startingBalanceMinor,
      },
      'settings': <Map<String, dynamic>>[
        for (final AppSetting setting in document.settings)
          <String, dynamic>{'key': setting.key, 'value': setting.value},
      ],
      'accounts': <Map<String, dynamic>>[
        for (final Account account in document.accounts)
          <String, dynamic>{
            'id': account.id,
            'uuid': account.uuid,
            'createdAt': _iso(account.createdAt),
            'updatedAt': _iso(account.updatedAt),
            if (account.deletedAt != null)
              'deletedAt': _iso(account.deletedAt!),
            'name': account.name,
            'type': account.type.name,
            'openingBalanceMinor': account.openingBalanceMinor,
            'colorValue': account.colorValue,
            'sortOrder': account.sortOrder,
            'isArchived': account.isArchived,
          },
      ],
      'categories': <Map<String, dynamic>>[
        for (final Category category in document.categories)
          <String, dynamic>{
            'id': category.id,
            'uuid': category.uuid,
            'createdAt': _iso(category.createdAt),
            'updatedAt': _iso(category.updatedAt),
            if (category.deletedAt != null)
              'deletedAt': _iso(category.deletedAt!),
            'name': category.name,
            'kind': category.kind.name,
            'iconKey': category.iconKey,
            'colorValue': category.colorValue,
            'sortOrder': category.sortOrder,
            'isArchived': category.isArchived,
          },
      ],
      'transactions': <Map<String, dynamic>>[
        for (final Transaction transaction in document.transactions)
          <String, dynamic>{
            'id': transaction.id,
            'uuid': transaction.uuid,
            'createdAt': _iso(transaction.createdAt),
            'updatedAt': _iso(transaction.updatedAt),
            if (transaction.deletedAt != null)
              'deletedAt': _iso(transaction.deletedAt!),
            'accountId': transaction.accountId,
            'categoryId': transaction.categoryId,
            'type': transaction.type.name,
            'amountMinor': transaction.amountMinor,
            if (transaction.person != null) 'person': transaction.person,
            if (transaction.note != null) 'note': transaction.note,
            'date': _iso(transaction.date),
            if (transaction.imagePath != null)
              'imagePath': transaction.imagePath,
            if (transaction.recurringRuleId != null)
              'recurringRuleId': transaction.recurringRuleId,
          },
      ],
      'debts': <Map<String, dynamic>>[
        for (final Debt debt in document.debts)
          <String, dynamic>{
            'id': debt.id,
            'uuid': debt.uuid,
            'createdAt': _iso(debt.createdAt),
            'updatedAt': _iso(debt.updatedAt),
            if (debt.deletedAt != null) 'deletedAt': _iso(debt.deletedAt!),
            'person': debt.person,
            'direction': debt.direction.name,
            'principalMinor': debt.principalMinor,
            if (debt.dueDate != null) 'dueDate': _iso(debt.dueDate!),
            if (debt.note != null) 'note': debt.note,
            if (debt.accountId != null) 'accountId': debt.accountId,
          },
      ],
      'debtPayments': <Map<String, dynamic>>[
        for (final DebtPayment payment in document.debtPayments)
          <String, dynamic>{
            'id': payment.id,
            'uuid': payment.uuid,
            'createdAt': _iso(payment.createdAt),
            'updatedAt': _iso(payment.updatedAt),
            if (payment.deletedAt != null)
              'deletedAt': _iso(payment.deletedAt!),
            'debtId': payment.debtId,
            'amountMinor': payment.amountMinor,
            'paidAt': _iso(payment.paidAt),
            if (payment.note != null) 'note': payment.note,
            if (payment.accountId != null) 'accountId': payment.accountId,
          },
      ],
      'budgets': <Map<String, dynamic>>[
        for (final Budget budget in document.budgets)
          <String, dynamic>{
            'id': budget.id,
            'uuid': budget.uuid,
            'createdAt': _iso(budget.createdAt),
            'updatedAt': _iso(budget.updatedAt),
            if (budget.deletedAt != null) 'deletedAt': _iso(budget.deletedAt!),
            'categoryId': budget.categoryId,
            'limitMinor': budget.limitMinor,
          },
      ],
      'recurringRules': <Map<String, dynamic>>[
        for (final RecurringRule rule in document.recurringRules)
          <String, dynamic>{
            'id': rule.id,
            'uuid': rule.uuid,
            'createdAt': _iso(rule.createdAt),
            'updatedAt': _iso(rule.updatedAt),
            if (rule.deletedAt != null) 'deletedAt': _iso(rule.deletedAt!),
            'accountId': rule.accountId,
            'categoryId': rule.categoryId,
            'type': rule.type.name,
            'amountMinor': rule.amountMinor,
            if (rule.person != null) 'person': rule.person,
            if (rule.note != null) 'note': rule.note,
            'frequency': rule.frequency.name,
            'startDate': _iso(rule.startDate),
            'nextDueDate': _iso(rule.nextDueDate),
            if (rule.endDate != null) 'endDate': _iso(rule.endDate!),
            'isActive': rule.isActive,
          },
      ],
      'receipts': <String, String>{
        for (final MapEntry<String, Uint8List> entry
            in document.receipts.entries)
          entry.key: base64Encode(entry.value),
      },
    });
  }

  static BackupDocument decode(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException {
      throw const BackupException('This file is not valid JSON.');
    }

    final Map<String, dynamic> root = _map(raw, 'backup');
    final String format = _string(root, 'format', 'backup');
    if (format != BackupFormat.name) {
      throw const BackupException(
        'This is not a Smart Wallet backup file.',
      );
    }

    final int version = _int(root, 'version', 'backup');
    if (version != BackupFormat.version) {
      throw BackupException(
        'Unsupported backup version ($version).',
      );
    }

    final int schemaVersion =
        _int(root, 'appSchemaVersion', 'backup', min: 1);
    if (schemaVersion > BackupFormat.appSchemaVersion) {
      throw const BackupException(
        'This backup was created by a newer version of the app.',
      );
    }

    final BackupDocument document = BackupDocument(
      exportedAt: _date(root, 'exportedAt', 'backup'),
      profile: _profile(_map(root['profile'], 'profile')),
      settings: _objects(root['settings'], 'settings', _setting),
      accounts: _objects(root['accounts'], 'accounts', _account),
      categories: _objects(root['categories'], 'categories', _category),
      transactions:
          _objects(root['transactions'], 'transactions', _transaction),
      debts: _objects(root['debts'], 'debts', _debt),
      debtPayments:
          _objects(root['debtPayments'], 'debtPayments', _debtPayment),
      budgets: _objects(root['budgets'], 'budgets', _budget),
      recurringRules:
          _objects(root['recurringRules'], 'recurringRules', _recurringRule),
      receipts: _receipts(root['receipts']),
    );

    _validate(document);
    return document;
  }

  static BackupProfile _profile(Map<String, dynamic> json) {
    final String name = _string(json, 'name', 'profile', max: 120);
    final int startingBalanceMinor =
        _int(json, 'startingBalanceMinor', 'profile', min: 0);
    return BackupProfile(
      name: name,
      startingBalanceMinor: startingBalanceMinor,
    );
  }

  static AppSetting _setting(Map<String, dynamic> json, String path) {
    return AppSetting(
      key: _string(json, 'key', path, max: 120),
      value: _string(json, 'value', path, allowEmpty: true),
    );
  }

  static Account _account(Map<String, dynamic> json, String path) {
    return Account(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      name: _string(json, 'name', path, max: 60),
      type: _enumValue(
        AccountType.values,
        json['type'],
        '$path.type',
      ),
      openingBalanceMinor: _int(json, 'openingBalanceMinor', path),
      colorValue: _int(json, 'colorValue', path),
      sortOrder: _int(json, 'sortOrder', path),
      isArchived: _bool(json, 'isArchived', path),
    );
  }

  static Category _category(Map<String, dynamic> json, String path) {
    return Category(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      name: _string(json, 'name', path, max: 40),
      kind: _enumValue(
        CategoryKind.values,
        json['kind'],
        '$path.kind',
      ),
      iconKey: _string(json, 'iconKey', path, max: 80),
      colorValue: _int(json, 'colorValue', path),
      sortOrder: _int(json, 'sortOrder', path),
      isArchived: _bool(json, 'isArchived', path),
    );
  }

  static Transaction _transaction(Map<String, dynamic> json, String path) {
    return Transaction(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      accountId: _int(json, 'accountId', path, min: 1),
      categoryId: _int(json, 'categoryId', path, min: 1),
      type: _enumValue(
        TransactionType.values,
        json['type'],
        '$path.type',
      ),
      amountMinor: _int(json, 'amountMinor', path, min: 1),
      person: _optionalString(json, 'person', path, max: 80),
      note: _optionalString(json, 'note', path, max: 500),
      date: _date(json, 'date', path),
      imagePath: _optionalString(json, 'imagePath', path, max: 300),
      recurringRuleId: _optionalInt(json, 'recurringRuleId', path, min: 1),
    );
  }

  static Debt _debt(Map<String, dynamic> json, String path) {
    return Debt(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      person: _string(json, 'person', path, max: 80),
      direction: _enumValue(
        DebtDirection.values,
        json['direction'],
        '$path.direction',
      ),
      principalMinor: _int(json, 'principalMinor', path, min: 1),
      dueDate: _optionalDate(json, 'dueDate', path),
      note: _optionalString(json, 'note', path, max: 500),
      accountId: _optionalInt(json, 'accountId', path, min: 1),
    );
  }

  static DebtPayment _debtPayment(Map<String, dynamic> json, String path) {
    return DebtPayment(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      debtId: _int(json, 'debtId', path, min: 1),
      amountMinor: _int(json, 'amountMinor', path, min: 1),
      paidAt: _date(json, 'paidAt', path),
      note: _optionalString(json, 'note', path, max: 500),
      accountId: _optionalInt(json, 'accountId', path, min: 1),
    );
  }

  static Budget _budget(Map<String, dynamic> json, String path) {
    return Budget(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      categoryId: _int(json, 'categoryId', path, min: 1),
      limitMinor: _int(json, 'limitMinor', path, min: 1),
    );
  }

  static RecurringRule _recurringRule(
    Map<String, dynamic> json,
    String path,
  ) {
    return RecurringRule(
      uuid: _string(json, 'uuid', path, max: 64),
      createdAt: _date(json, 'createdAt', path),
      updatedAt: _date(json, 'updatedAt', path),
      deletedAt: _optionalDate(json, 'deletedAt', path),
      id: _int(json, 'id', path, min: 1),
      accountId: _int(json, 'accountId', path, min: 1),
      categoryId: _int(json, 'categoryId', path, min: 1),
      type: _enumValue(
        TransactionType.values,
        json['type'],
        '$path.type',
      ),
      amountMinor: _int(json, 'amountMinor', path, min: 1),
      person: _optionalString(json, 'person', path, max: 80),
      note: _optionalString(json, 'note', path, max: 500),
      frequency: _enumValue(
        RecurrenceFrequency.values,
        json['frequency'],
        '$path.frequency',
      ),
      startDate: _date(json, 'startDate', path),
      nextDueDate: _date(json, 'nextDueDate', path),
      endDate: _optionalDate(json, 'endDate', path),
      isActive: _bool(json, 'isActive', path),
    );
  }

  static Map<String, Uint8List> _receipts(Object? raw) {
    if (raw == null) {
      return <String, Uint8List>{};
    }
    final Map<String, dynamic> json = _map(raw, 'receipts');
    final Map<String, Uint8List> result = <String, Uint8List>{};
    for (final MapEntry<String, dynamic> entry in json.entries) {
      final String path = entry.key;
      if (!_receiptPath.hasMatch(path) || path.contains('..')) {
        throw BackupException('Invalid receipt path: $path');
      }
      if (entry.value is! String) {
        throw BackupException('Receipt $path is not valid base64.');
      }
      final Uint8List bytes;
      try {
        bytes = base64Decode(entry.value as String);
      } on FormatException {
        throw BackupException('Receipt $path is not valid base64.');
      }
      if (bytes.isEmpty) {
        throw BackupException('Receipt $path is empty.');
      }
      result[path] = bytes;
    }
    return result;
  }

  static void _validate(BackupDocument document) {
    if (document.accounts.isEmpty) {
      throw const BackupException(
        'The backup does not contain an account.',
      );
    }

    _uniqueIds(document.accounts, (Account a) => a.id, (Account a) => a.uuid,
        'account');
    _uniqueIds(
      document.categories,
      (Category c) => c.id,
      (Category c) => c.uuid,
      'category',
    );
    _uniqueIds(
      document.transactions,
      (Transaction t) => t.id,
      (Transaction t) => t.uuid,
      'transaction',
    );
    _uniqueIds(document.debts, (Debt d) => d.id, (Debt d) => d.uuid, 'debt');
    _uniqueIds(
      document.debtPayments,
      (DebtPayment p) => p.id,
      (DebtPayment p) => p.uuid,
      'debt payment',
    );
    _uniqueIds(
      document.budgets,
      (Budget b) => b.id,
      (Budget b) => b.uuid,
      'budget',
    );
    _uniqueIds(
      document.recurringRules,
      (RecurringRule r) => r.id,
      (RecurringRule r) => r.uuid,
      'recurring rule',
    );

    final Set<int> accountIds =
        document.accounts.map((Account a) => a.id).toSet();
    final Set<int> categoryIds =
        document.categories.map((Category c) => c.id).toSet();
    final Set<int> debtIds = document.debts.map((Debt d) => d.id).toSet();
    final Set<int> ruleIds =
        document.recurringRules.map((RecurringRule r) => r.id).toSet();
    final Set<int> budgetCategoryIds = <int>{};
    final Set<String> settingKeys = <String>{};

    for (final AppSetting setting in document.settings) {
      if (!settingKeys.add(setting.key)) {
        throw BackupException('Duplicate setting: ${setting.key}');
      }
    }

    for (final Transaction transaction in document.transactions) {
      if (!accountIds.contains(transaction.accountId)) {
        throw BackupException(
          'Transaction ${transaction.id} refers to a missing account.',
        );
      }
      if (!categoryIds.contains(transaction.categoryId)) {
        throw BackupException(
          'Transaction ${transaction.id} refers to a missing category.',
        );
      }
      if (transaction.recurringRuleId != null &&
          !ruleIds.contains(transaction.recurringRuleId)) {
        throw BackupException(
          'Transaction ${transaction.id} refers to a missing recurring rule.',
        );
      }
      if (transaction.imagePath != null &&
          !_receiptPath.hasMatch(transaction.imagePath!)) {
        throw BackupException(
          'Transaction ${transaction.id} has an invalid receipt path.',
        );
      }
    }

    for (final Debt debt in document.debts) {
      if (debt.accountId != null && !accountIds.contains(debt.accountId)) {
        throw BackupException(
          'Debt ${debt.id} refers to a missing account.',
        );
      }
    }

    for (final DebtPayment payment in document.debtPayments) {
      if (!debtIds.contains(payment.debtId)) {
        throw BackupException(
          'Debt payment ${payment.id} refers to a missing debt.',
        );
      }
      if (payment.accountId != null &&
          !accountIds.contains(payment.accountId)) {
        throw BackupException(
          'Debt payment ${payment.id} refers to a missing account.',
        );
      }
    }

    for (final Budget budget in document.budgets) {
      if (!categoryIds.contains(budget.categoryId)) {
        throw BackupException(
          'Budget ${budget.id} refers to a missing category.',
        );
      }
      if (!budgetCategoryIds.add(budget.categoryId)) {
        throw BackupException(
          'Category ${budget.categoryId} has more than one budget.',
        );
      }
    }

    for (final RecurringRule rule in document.recurringRules) {
      if (!accountIds.contains(rule.accountId)) {
        throw BackupException(
          'Recurring rule ${rule.id} refers to a missing account.',
        );
      }
      if (!categoryIds.contains(rule.categoryId)) {
        throw BackupException(
          'Recurring rule ${rule.id} refers to a missing category.',
        );
      }
    }
  }

  static void _uniqueIds<T>(
    List<T> items,
    int Function(T) idOf,
    String Function(T) uuidOf,
    String label,
  ) {
    final Set<int> ids = <int>{};
    final Set<String> uuids = <String>{};
    for (final T item in items) {
      if (!ids.add(idOf(item))) {
        throw BackupException('Duplicate $label id: ${idOf(item)}');
      }
      if (!uuids.add(uuidOf(item))) {
        throw BackupException('Duplicate $label uuid: ${uuidOf(item)}');
      }
    }
  }

  static List<T> _objects<T>(
    Object? raw,
    String field,
    T Function(Map<String, dynamic> json, String path) parse,
  ) {
    final List<dynamic> list = _list(raw, field);
    return <T>[
      for (int i = 0; i < list.length; i++)
        parse(_map(list[i], '$field[$i]'), '$field[$i]'),
    ];
  }

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    throw BackupException('$field is not an object.');
  }

  static List<dynamic> _list(Object? value, String field) {
    if (value == null) {
      return const <dynamic>[];
    }
    if (value is List) {
      return value;
    }
    throw BackupException('$field is not a list.');
  }

  static String _string(
    Map<String, dynamic> json,
    String key,
    String path, {
    bool allowEmpty = false,
    int? max,
  }) {
    final Object? raw = json[key];
    if (raw is! String) {
      throw BackupException('$path.$key is missing or not text.');
    }
    final String value = raw.trim();
    if (!allowEmpty && value.isEmpty) {
      throw BackupException('$path.$key cannot be empty.');
    }
    if (max != null && value.length > max) {
      throw BackupException('$path.$key is too long.');
    }
    return value;
  }

  static String? _optionalString(
    Map<String, dynamic> json,
    String key,
    String path, {
    int? max,
  }) {
    final Object? raw = json[key];
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw BackupException('$path.$key is not text.');
    }
    final String value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    if (max != null && value.length > max) {
      throw BackupException('$path.$key is too long.');
    }
    return value;
  }

  static int _int(
    Map<String, dynamic> json,
    String key,
    String path, {
    int? min,
    int? max,
  }) {
    final Object? raw = json[key];
    final int? value = switch (raw) {
      int v => v,
      num v when v == v.roundToDouble() => v.toInt(),
      _ => null,
    };
    if (value == null) {
      throw BackupException('$path.$key is missing or not a number.');
    }
    if (min != null && value < min) {
      throw BackupException('$path.$key is too small.');
    }
    if (max != null && value > max) {
      throw BackupException('$path.$key is too large.');
    }
    return value;
  }

  static int? _optionalInt(
    Map<String, dynamic> json,
    String key,
    String path, {
    int? min,
    int? max,
  }) {
    if (json[key] == null) {
      return null;
    }
    return _int(json, key, path, min: min, max: max);
  }

  static bool _bool(Map<String, dynamic> json, String key, String path) {
    final Object? raw = json[key];
    if (raw is! bool) {
      throw BackupException('$path.$key is missing or not true/false.');
    }
    return raw;
  }

  static DateTime _date(Map<String, dynamic> json, String key, String path) {
    final Object? raw = json[key];
    if (raw is! String) {
      throw BackupException('$path.$key is missing or not a date.');
    }
    final DateTime? value = DateTime.tryParse(raw);
    if (value == null) {
      throw BackupException('$path.$key is not a valid date.');
    }
    return value;
  }

  static DateTime? _optionalDate(
    Map<String, dynamic> json,
    String key,
    String path,
  ) {
    if (json[key] == null) {
      return null;
    }
    return _date(json, key, path);
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    Object? raw,
    String path,
  ) {
    if (raw is! String) {
      throw BackupException('$path is missing or not text.');
    }
    for (final T value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    throw BackupException('$path has an unknown value: $raw');
  }

  static String _iso(DateTime value) => value.toIso8601String();
}
