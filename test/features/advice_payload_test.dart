import 'package:flutter_test/flutter_test.dart';
import 'package:smartwallete/core/database/app_database.dart';
import 'package:smartwallete/core/money/display.dart';
import 'package:smartwallete/features/stats/data/advice_payload.dart';
import 'package:smartwallete/features/stats/data/stats_repository.dart';

void main() {
  test('buildAdvicePrompt includes aggregates and stays person-safe', () {
    final Category food = Category(
      id: 1,
      uuid: 'u1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      deletedAt: null,
      name: 'Food',
      kind: CategoryKind.expense,
      iconKey: 'food',
      colorValue: 0xFF00FF00,
      sortOrder: 0,
      isArchived: false,
    );

    final StatsSummary summary = StatsSummary(
      month: DateTime(2026, 11),
      totalMinor: 10000,
      categories: <CategorySpend>[
        CategorySpend(category: food, amountMinor: 6000),
      ],
      persons: const <PersonSpend>[
        PersonSpend(person: 'SecretPerson', amountMinor: 6000),
      ],
      months: <MonthSpend>[
        MonthSpend(month: DateTime(2026, 10), amountMinor: 8000),
        MonthSpend(month: DateTime(2026, 11), amountMinor: 10000),
      ],
    );

    final String prompt = buildAdvicePrompt(summary);

    expect(prompt, contains('November 2026'));
    expect(prompt, contains(formatMinor(10000)));
    expect(prompt, contains('Food'));
    expect(prompt, contains('60%'));
    expect(prompt, isNot(contains('SecretPerson')));
    expect(advicePromptLooksSafe(prompt), isTrue);
  });
}
