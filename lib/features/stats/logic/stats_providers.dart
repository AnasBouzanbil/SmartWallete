import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/logic/transaction_providers.dart';
import '../data/stats_repository.dart';

final Provider<StatsRepository> statsRepositoryProvider =
    Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(transactionRepositoryProvider));
});

final statsProvider =
    StreamProvider.family<StatsSummary, DateTime>((ref, DateTime month) {
  return ref.watch(statsRepositoryProvider).watch(month);
});

final StreamProvider<StatsSummary> currentStatsProvider =
    StreamProvider<StatsSummary>((ref) {
  final DateTime now = DateTime.now();
  return ref.watch(statsRepositoryProvider).watch(DateTime(now.year, now.month));
});
