import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/debt_notification_service.dart';
import '../data/debt_repository.dart';
import 'debt_providers.dart';

/// Keeps local due-date notifications in sync with open debts.
final Provider<void> debtNotificationSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<DebtSummary>>>(
    debtsProvider,
    (AsyncValue<List<DebtSummary>>? previous,
        AsyncValue<List<DebtSummary>> next) {
      next.whenData((List<DebtSummary> debts) {
        DebtNotificationService.instance.syncDebts(debts);
      });
    },
    fireImmediately: true,
  );
});
