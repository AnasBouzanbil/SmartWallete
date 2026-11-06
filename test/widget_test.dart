import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/core/database/database_provider.dart';
import 'package:smartwallete/features/auth/logic/auth_providers.dart';
import 'package:smartwallete/main.dart';

import 'fakes.dart';

void main() {
  testWidgets('first launch opens the setup screen', (
    WidgetTester tester,
  ) async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          credentialsStoreProvider.overrideWithValue(FakeCredentialsStore()),
          biometricServiceProvider.overrideWithValue(FakeBiometricService()),
        ],
        child: const SmartWalletApp(),
      ),
    );
    // Initial load is async; let it settle.
    await tester.pumpAndSettle();

    expect(find.text('Create your wallet'), findsOneWidget);
    expect(find.text('Create wallet'), findsOneWidget);
  });
}
