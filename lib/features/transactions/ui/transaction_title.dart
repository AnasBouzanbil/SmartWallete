import '../../../core/database/app_database.dart';
import '../data/transaction_repository.dart';

/// Note → person → category name.
String transactionTitle(TransactionWithCategory item) {
  final Transaction tx = item.transaction;
  final String? note = tx.note?.trim();
  if (note != null && note.isNotEmpty) {
    return note;
  }
  final String? person = tx.person?.trim();
  if (person != null && person.isNotEmpty) {
    return person;
  }
  return item.category.name;
}
