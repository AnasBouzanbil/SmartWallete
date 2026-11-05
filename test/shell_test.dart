import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/theme/app_theme.dart';
import 'package:smartwallete/features/auth/data/password_hasher.dart';
import 'package:smartwallete/features/auth/data/user_credentials.dart';
import 'package:smartwallete/features/auth/logic/auth_providers.dart';
import 'package:smartwallete/features/debts/data/debt_repository.dart';
import 'package:smartwallete/features/debts/logic/debt_providers.dart';
import 'package:smartwallete/features/shell/app_shell.dart';
import 'package:smartwallete/features/stats/data/stats_repository.dart';
import 'package:smartwallete/features/stats/logic/stats_providers.dart';
import 'package:smartwallete/features/transactions/data/transaction_repository.dart';
import 'package:smartwallete/features/transactions/logic/transaction_providers.dart';

import 'fakes.dart';

void main() {
  testWidgets('the shell renders home, debts, stats and settings', (
    WidgetTester tester,
  ) async {
    const PasswordHasher hasher = PasswordHasher(iterations: 1000);
    final FakeCredentialsStore store = FakeCredentialsStore();
    await store.write(
      UserCredentials(
        name: 'Sara',
        startingBalance: 1000,
        passwordHash: (await hasher.hash('secret1')).encode(),
        fingerprintEnabled: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          credentialsStoreProvider.overrideWithValue(store),
          passwordHasherProvider.overrideWithValue(hasher),
          biometricServiceProvider.overrideWithValue(FakeBiometricService()),
          netMinorProvider.overrideWith((ref) => Stream<int>.value(0)),
          recentTransactionsProvider.overrideWith(
            (ref) => Stream<List<TransactionWithCategory>>.value(
              const <TransactionWithCategory>[],
            ),
          ),
          monthlyTotalsProvider.overrideWith(
            (ref, DateTime month) =>
                Stream<MonthlyTotals>.value(MonthlyTotals.zero),
          ),
          debtsProvider.overrideWith(
            (ref) => Stream<List<DebtSummary>>.value(const <DebtSummary>[]),
          ),
          currentStatsProvider.overrideWith(
            (ref) =>
                Stream<StatsSummary>.value(StatsSummary.empty(DateTime.now())),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total balance'), findsOneWidget);

    await tester.tap(find.text('Debts'));
    await tester.pumpAndSettle();
    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('No open debts'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Statistics'), findsOneWidget);

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Export JSON'), findsOneWidget);
    expect(find.text('Import JSON'), findsOneWidget);
  });
}
