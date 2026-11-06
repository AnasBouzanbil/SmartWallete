import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/core/database/database_provider.dart';
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
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
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
          databaseProvider.overrideWithValue(db),
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
          statsProvider.overrideWith(
            (ref, DateTime month) =>
                Stream<StatsSummary>.value(StatsSummary.empty(month)),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total balance'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Debts'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You owe'), findsWidgets);
    expect(find.text('No open debts'), findsWidgets);
    expect(find.text('Add debt'), findsWidgets);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Stats'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Statistics'), findsOneWidget);

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
