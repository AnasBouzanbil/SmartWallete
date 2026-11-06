import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/transaction_repository.dart';
import '../logic/transaction_providers.dart';
import 'add_transaction_screen.dart';
import 'transaction_tile.dart';

enum _TypeFilter { all, expense, income }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _search = TextEditingController();
  _TypeFilter _filter = _TypeFilter.all;
  String _query = '';

  /// Ids swiped away but not yet removed by the database stream. Keeps the
  /// dismissed row out of the tree immediately (Dismissible requires it).
  final Set<int> _removed = <int>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<TransactionWithCategory> _apply(List<TransactionWithCategory> items) {
    final String q = _query.trim().toLowerCase();
    return items.where((TransactionWithCategory item) {
      final Transaction tx = item.transaction;
      if (_removed.contains(tx.id)) {
        return false;
      }
      if (_filter == _TypeFilter.expense &&
          tx.type != TransactionType.expense) {
        return false;
      }
      if (_filter == _TypeFilter.income && tx.type != TransactionType.income) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      final String haystack = <String>[
        item.category.name,
        tx.person ?? '',
        tx.note ?? '',
        formatMinor(tx.amountMinor),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }

  Future<void> _delete(TransactionWithCategory item) async {
    final TransactionRepository repo = ref.read(transactionRepositoryProvider);
    final int id = item.transaction.id;
    HapticFeedback.mediumImpact();
    setState(() => _removed.add(id));
    await repo.delete(id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.restore(id);
              if (mounted) {
                setState(() => _removed.remove(id));
              }
            },
          ),
        ),
      );
  }

  void _openAdd() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AddTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final AsyncValue<List<TransactionWithCategory>> transactions =
        ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: const Text('All transactions'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: _openAdd,
        child: const Icon(PhosphorIconsRegular.plus),
      ),
      body: SafeArea(
        child: transactions.when(
          data: (List<TransactionWithCategory> all) {
            final List<TransactionWithCategory> items = _apply(all);
            final bool filtering =
                _query.trim().isNotEmpty || _filter != _TypeFilter.all;

            return ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space8,
                AppSpacing.space16,
                96,
              ),
              children: <Widget>[
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (String value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search note, person, category or amount',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                PillTabs(
                  index: _filter.index,
                  labels: const <String>['All', 'Expenses', 'Income'],
                  onChanged: (int i) =>
                      setState(() => _filter = _TypeFilter.values[i]),
                ),
                const SizedBox(height: AppSpacing.space16),
                if (all.isEmpty)
                  _EmptyList(onAdd: _openAdd)
                else if (items.isEmpty)
                  _NoResults(
                    query: _query.trim(),
                    onReset: () {
                      _search.clear();
                      setState(() {
                        _query = '';
                        _filter = _TypeFilter.all;
                      });
                    },
                  )
                else ...<Widget>[
                  if (filtering) _ResultsSummary(items: items),
                  ..._buildGroups(items, colors),
                ],
              ],
            );
          },
          loading: () => ListView(
            padding: AppSpacing.page,
            children: const <Widget>[TransactionListSkeleton(rows: 6)],
          ),
          error: (Object error, StackTrace stack) => Center(
            child: Text(
              'Could not load transactions.',
              style: TextStyle(color: colors.expense),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
    List<TransactionWithCategory> items,
    AppColorSet colors,
  ) {
    final Map<DateTime, List<TransactionWithCategory>> groups =
        <DateTime, List<TransactionWithCategory>>{};
    for (final TransactionWithCategory item in items) {
      final DateTime d = item.transaction.date;
      final DateTime key = DateTime(d.year, d.month, d.day);
      (groups[key] ??= <TransactionWithCategory>[]).add(item);
    }

    final ThemeData theme = Theme.of(context);
    final List<Widget> out = <Widget>[];
    groups.forEach((DateTime day, List<TransactionWithCategory> rows) {
      int net = 0;
      for (final TransactionWithCategory r in rows) {
        net += r.transaction.type == TransactionType.income
            ? r.transaction.amountMinor
            : -r.transaction.amountMinor;
      }

      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space8,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _dayLabel(day),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatMinor(net, showSign: true),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: net > 0 ? colors.income : colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      out.add(
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0) Divider(height: 1, color: colors.outline),
                Dismissible(
                  key: ValueKey<int>(rows[i].transaction.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(rows[i]),
                  background: Container(
                    color: colors.expense.withValues(alpha: 0.2),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.space24),
                    child: Icon(
                      PhosphorIconsRegular.trash,
                      color: colors.expense,
                    ),
                  ),
                  child: ColoredBox(
                    color: colors.surface,
                    child: TransactionTile(item: rows[i], showDate: false),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      out.add(const SizedBox(height: AppSpacing.space8));
    });
    return out;
  }

  String _dayLabel(DateTime day) {
    final String base = shortDate(day);
    // "Today"/"Yesterday"/weekday read better with the actual date next to them.
    if (base.contains(' ')) {
      return base;
    }
    return '$base · ${day.day} ${shortMonthName(day)}';
  }
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.items});

  final List<TransactionWithCategory> items;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    int income = 0;
    int expense = 0;
    for (final TransactionWithCategory item in items) {
      if (item.transaction.type == TransactionType.income) {
        income += item.transaction.amountMinor;
      } else {
        expense += item.transaction.amountMinor;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Text(
        '${items.length} ${items.length == 1 ? 'result' : 'results'} · '
        '${formatMinor(income, showSign: true)} in · '
        '${formatMinor(-expense, showSign: true)} out',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space32),
      child: Column(
        children: <Widget>[
          Icon(
            PhosphorIconsRegular.receipt,
            size: AppSpacing.iconXl,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.space16),
          Text('No transactions yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Add your first expense or income to start tracking.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(PhosphorIconsRegular.plus),
            label: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onReset});

  final String query;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space32),
      child: Column(
        children: <Widget>[
          Icon(Icons.search_off, size: AppSpacing.iconXl, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.space16),
          Text(
            query.isEmpty ? 'Nothing matches this filter' : 'No results for "$query"',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space8),
          TextButton(onPressed: onReset, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}
