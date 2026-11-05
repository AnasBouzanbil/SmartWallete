// Domain enums used by the database tables.
//
// Stored as text (via Drift's EnumNameConverter) so values are readable in
// the database and stay stable if the enum order ever changes.

/// Whether a transaction adds money (income) or removes it (expense).
enum TransactionType { income, expense }

/// Direction of a debt from the user's point of view.
///
/// [lent]  -> "I lent money" (the other person owes me).
/// [owed]  -> "I owe money" (I owe the other person).
enum DebtDirection { lent, owed }

/// Kind of account (a "pocket" of money).
enum AccountType { cash, bank, savings, other }

/// Which transaction type a category applies to.
enum CategoryKind { income, expense }

/// How often a recurring rule repeats.
enum RecurrenceFrequency { weekly, monthly, yearly }
