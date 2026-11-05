// Domain enums used by the database tables.
//
// Stored as text (via Drift's EnumNameConverter) so the values are readable
// in the database and stable if the enum order ever changes.

/// Whether a transaction adds money (income) or removes it (expense).
enum TransactionType { income, expense }

/// The direction of a debt from the user's point of view.
///
/// [lent]  -> "I lent money" (the other person owes me).
/// [owed]  -> "I owe money" (I owe the other person).
enum DebtDirection { lent, owed }
