import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/debt_repository.dart';

final Provider<DebtRepository> debtRepositoryProvider =
    Provider<DebtRepository>((ref) {
  return DebtRepository(ref.watch(databaseProvider));
});

final StreamProvider<List<DebtSummary>> debtsProvider =
    StreamProvider<List<DebtSummary>>((ref) {
  return ref.watch(debtRepositoryProvider).watchAll();
});

final debtPaymentsProvider =
    StreamProvider.family<List<DebtPayment>, int>((ref, int debtId) {
  return ref.watch(debtRepositoryProvider).watchPayments(debtId);
});
