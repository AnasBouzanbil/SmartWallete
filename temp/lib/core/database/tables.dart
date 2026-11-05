import 'package:drift/drift.dart';

import 'enums.dart';

// Columns for enum values are stored as text via EnumNameConverter.
// The concrete converter instances live in database_connection.dart.

/// A money movement: either income or an expense.
@DataClassName('Transaction')
class Transactions extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Income or expense.
  TextColumn get type =>
      text().map(const EnumNameConverter<TransactionType>(TransactionType.values))();

  /// Amount in the app's currency. Must be strictly positive.
  RealColumn get amount => real().customConstraint('NOT NULL CHECK (amount > 0)')();

  /// Who the transaction was with (optional).
  TextColumn get person => text().nullable()();

  /// Why / free-text note (optional).
  TextColumn get note => text().nullable()();

  /// Category label (e.g. "Food", "Rent").
  TextColumn get category => text()();

  /// When the transaction happened.
  DateTimeColumn get date => dateTime()();

  /// Path to an optional attached image in the app documents folder.
  TextColumn get imagePath => text().nullable()();
}

/// A debt tracked separately from transactions.
@DataClassName('Debt')
class Debts extends Table {
  /// Auto-incrementing primary key.
  IntColumn get id => integer().autoIncrement()();

  /// The other person.
  TextColumn get person => text()();

  /// Amount in the app's currency. Must be strictly positive.
  RealColumn get amount => real().customConstraint('NOT NULL CHECK (amount > 0)')();

  /// Whether I lent money or I owe money.
  TextColumn get direction =>
      text().map(const EnumNameConverter<DebtDirection>(DebtDirection.values))();

  /// Optional due date used for reminders.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Free-text note (optional).
  TextColumn get note => text().nullable()();

  /// Whether this debt is settled. Defaults to false.
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();

  /// When the debt record was created.
  DateTimeColumn get createdAt => dateTime()();
}
