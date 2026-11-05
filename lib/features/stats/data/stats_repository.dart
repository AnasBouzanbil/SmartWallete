import '../../../core/database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';

class CategorySpend {
  const CategorySpend({required this.category, required this.amountMinor});

  final Category category;
  final int amountMinor;
}

class PersonSpend {
  const PersonSpend({required this.person, required this.amountMinor});

  final String person;
  final int amountMinor;
}

class MonthSpend {
  const MonthSpend({required this.month, required this.amountMinor});

  final DateTime month;
  final int amountMinor;
}

class StatsSummary {
  const StatsSummary({
    required this.month,
    required this.categories,
    required this.persons,
    required this.months,
    required this.totalMinor,
  });

  static StatsSummary empty(DateTime month) => StatsSummary(
        month: month,
        categories: const <CategorySpend>[],
        persons: const <PersonSpend>[],
        months: const <MonthSpend>[],
        totalMinor: 0,
      );

  final DateTime month;
  final List<CategorySpend> categories;
  final List<PersonSpend> persons;
  final List<MonthSpend> months;
  final int totalMinor;

  CategorySpend? get topCategory =>
      categories.isEmpty ? null : categories.first;

  double get topShare {
    if (totalMinor == 0 || categories.isEmpty) {
      return 0;
    }
    return categories.first.amountMinor / totalMinor;
  }

  factory StatsSummary.fromTransactions({
    required DateTime month,
    required List<TransactionWithCategory> transactions,
    int monthCount = 6,
  }) {
    final DateTime monthStart = DateTime(month.year, month.month);
    final DateTime nextMonth = DateTime(month.year, month.month + 1);

    final Map<int, CategorySpend> categoryMap = <int, CategorySpend>{};
    final Map<String, int> personMap = <String, int>{};
    final DateTime firstMonth =
        DateTime(month.year, month.month - (monthCount - 1));

    final Map<String, int> monthMap = <String, int>{};
    for (int i = 0; i < monthCount; i++) {
      final DateTime m = DateTime(firstMonth.year, firstMonth.month + i);
      monthMap[_monthKey(m)] = 0;
    }

    for (final TransactionWithCategory item in transactions) {
      final Transaction tx = item.transaction;
      final DateTime date = tx.date;
      final String key = _monthKey(date);
      if (monthMap.containsKey(key)) {
        monthMap[key] = monthMap[key]! + tx.amountMinor;
      }

      final bool inMonth =
          !date.isBefore(monthStart) && date.isBefore(nextMonth);
      if (!inMonth) {
        continue;
      }

      final CategorySpend? existing = categoryMap[item.category.id];
      categoryMap[item.category.id] = CategorySpend(
        category: item.category,
        amountMinor: (existing?.amountMinor ?? 0) + tx.amountMinor,
      );

      final String person = _personLabel(tx.person);
      personMap[person] = (personMap[person] ?? 0) + tx.amountMinor;
    }

    final List<CategorySpend> categories =
        categoryMap.values.toList(growable: false)
          ..sort((CategorySpend a, CategorySpend b) =>
              b.amountMinor.compareTo(a.amountMinor));

    final List<PersonSpend> persons = personMap.entries
        .map((MapEntry<String, int> e) =>
            PersonSpend(person: e.key, amountMinor: e.value))
        .toList(growable: false)
      ..sort((PersonSpend a, PersonSpend b) =>
          b.amountMinor.compareTo(a.amountMinor));

    final List<MonthSpend> months = <MonthSpend>[];
    for (int i = 0; i < monthCount; i++) {
      final DateTime m = DateTime(firstMonth.year, firstMonth.month + i);
      months.add(MonthSpend(month: m, amountMinor: monthMap[_monthKey(m)] ?? 0));
    }

    final int total = categories.fold<int>(
      0,
      (int sum, CategorySpend c) => sum + c.amountMinor,
    );

    return StatsSummary(
      month: monthStart,
      categories: categories,
      persons: persons,
      months: months,
      totalMinor: total,
    );
  }

  static String _monthKey(DateTime date) => '${date.year}-${date.month}';

  static String _personLabel(String? person) {
    final String? trimmed = person?.trim();
    return trimmed == null || trimmed.isEmpty ? 'No person' : trimmed;
  }
}

class StatsRepository {
  StatsRepository(this._transactions);

  final TransactionRepository _transactions;

  Stream<StatsSummary> watch(DateTime month, {int monthCount = 6}) {
    final DateTime firstMonth =
        DateTime(month.year, month.month - (monthCount - 1));
    final (DateTime _, DateTime end) = monthRange(month);

    return _transactions.watchExpensesInRange(firstMonth, end).map(
          (List<TransactionWithCategory> transactions) => StatsSummary.fromTransactions(
            month: month,
            transactions: transactions,
            monthCount: monthCount,
          ),
        );
  }
}
