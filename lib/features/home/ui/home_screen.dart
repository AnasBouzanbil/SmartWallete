import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/logic/auth_state.dart';
import '../../debts/data/debt_repository.dart';
import '../../debts/logic/debt_providers.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/logic/transaction_providers.dart';
import '../../transactions/ui/add_transaction_screen.dart';
import '../../transactions/ui/transaction_detail_screen.dart';
import '../../transactions/ui/transaction_title.dart';
import '../../transactions/ui/transactions_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onOpenDebts});

  final VoidCallback? onOpenDebts;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hideAmounts = false;

  void _openAdd(BuildContext context, TransactionType type) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            AddTransactionScreen(initialType: type),
      ),
    );
  }

  void _openAllTransactions(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const TransactionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AuthState auth = ref.watch(authControllerProvider);
    final DateTime now = DateTime.now();
    final DateTime month = DateTime(now.year, now.month);

    final AsyncValue<int> net = ref.watch(netMinorProvider);
    final AsyncValue<MonthlyTotals> totals = ref.watch(
      monthlyTotalsProvider(month),
    );
    final AsyncValue<List<TransactionWithCategory>> recent = ref.watch(
      recentTransactionsProvider,
    );
    final AsyncValue<List<DebtSummary>> debts = ref.watch(debtsProvider);

    final int totalMinor =
        majorToMinor(auth.startingBalance) + (net.asData?.value ?? 0);
    final MonthlyTotals monthTotals =
        totals.asData?.value ?? MonthlyTotals.zero;
    final DebtOverview overview = DebtOverview.from(
      debts.asData?.value ?? const <DebtSummary>[],
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space24,
          ),
          children: <Widget>[
            _Header(
              name: auth.name,
              onLock: () => ref.read(authControllerProvider.notifier).lock(),
            ),
            const SizedBox(height: AppSpacing.space24),
            _BalanceCard(
              totalMinor: totalMinor,
              incomeMinor: monthTotals.incomeMinor,
              expenseMinor: monthTotals.expenseMinor,
              hidden: _hideAmounts,
              onToggle: () => setState(() => _hideAmounts = !_hideAmounts),
            ),
            const SizedBox(height: AppSpacing.space16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickAction(
                    label: '+ Expense',
                    icon: PhosphorIconsRegular.arrowUpRight,
                    color: colors.expense,
                    background: colors.surface,
                    textColor: colors.textPrimary,
                    onTap: () => _openAdd(context, TransactionType.expense),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: _QuickAction(
                    label: '+ Income',
                    icon: PhosphorIconsRegular.arrowDownLeft,
                    color: colors.onAccent,
                    background: colors.accent,
                    textColor: colors.onAccent,
                    onTap: () => _openAdd(context, TransactionType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _DebtCard(
                    label: 'You owe',
                    amountMinor: overview.youOweMinor,
                    note: overview.youOweCount == 0
                        ? 'No debts'
                        : dueLabel(overview.nearestDueDate, now: now),
                    background: colors.debtOwed,
                    foreground: colors.debtOwedSurface,
                    muted: colors.debtOwedSurface.withValues(alpha: 0.7),
                    icon: PhosphorIconsRegular.arrowUpRight,
                    hidden: _hideAmounts,
                    onTap: widget.onOpenDebts,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: _DebtCard(
                    label: 'Owed to you',
                    amountMinor: overview.owedToYouMinor,
                    note: overview.owedToYouCount == 0
                        ? 'No debts'
                        : '${overview.owedToYouCount} '
                              '${overview.owedToYouCount == 1 ? 'person' : 'people'}',
                    background: colors.debtLentSurface,
                    foreground: colors.debtLent,
                    muted: colors.debtLent.withValues(alpha: 0.65),
                    icon: PhosphorIconsRegular.arrowDownLeft,
                    hidden: _hideAmounts,
                    onTap: widget.onOpenDebts,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space24),
            Row(
              children: <Widget>[
                Text(
                  'Recent',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _openAllTransactions(context),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            recent.when(
              data: (List<TransactionWithCategory> items) {
                if (items.isEmpty) {
                  return const _EmptyRecent();
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < items.length; i++) ...<Widget>[
                        if (i > 0) Divider(height: 1, color: colors.outline),
                        _TransactionRow(item: items[i], hidden: _hideAmounts),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const _RecentLoading(),
              error: (Object error, StackTrace stack) => _RecentError(
                onRetry: () => ref.invalidate(recentTransactionsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onLock});

  final String name;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final String initial = name.trim().isEmpty
        ? 'W'
        : name.trim().substring(0, 1).toUpperCase();

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.surfaceAlt,
          child: Text(
            initial,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name.trim().isEmpty ? 'My wallet' : '$name My wallet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Everything in one place',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Lock',
          onPressed: onLock,
          icon: const Icon(PhosphorIconsRegular.lockSimple),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.totalMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.hidden,
    required this.onToggle,
  });

  final int totalMinor;
  final int incomeMinor;
  final int expenseMinor;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Color ink = colors.onAccent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(AppSpacing.radius28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Total balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ink.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Icon(
                    hidden
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye,
                    size: AppSpacing.iconMd,
                    color: ink.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            formatMinor(totalMinor, masked: hidden),
            style: theme.textTheme.displaySmall?.copyWith(
              color: ink,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            '${formatMinor(incomeMinor, showSign: true, masked: hidden)} in · '
            '${formatMinor(expenseMinor, showSign: true, masked: hidden)} out',
            style: theme.textTheme.bodySmall?.copyWith(
              color: ink.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSpacing.radius20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: AppSpacing.iconSm, color: color),
              const SizedBox(width: AppSpacing.space8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({
    required this.label,
    required this.amountMinor,
    required this.note,
    required this.background,
    required this.foreground,
    required this.muted,
    required this.icon,
    required this.hidden,
    this.onTap,
  });

  final String label;
  final int amountMinor;
  final String note;
  final Color background;
  final Color foreground;
  final Color muted;
  final IconData icon;
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSpacing.radius20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: muted.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppSpacing.iconSm,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                formatMinor(amountMinor, masked: hidden),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, required this.hidden});

  final TransactionWithCategory item;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Transaction tx = item.transaction;
    final bool isIncome = tx.type == TransactionType.income;
    final Color amountColor = isIncome ? colors.income : colors.textPrimary;

    return InkWell(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                TransactionDetailScreen(transactionId: tx.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: <Widget>[
            CategoryAvatar(category: item.category),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    transactionTitle(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.category.name} · ${shortDate(tx.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Text(
              formatMinor(
                isIncome ? tx.amountMinor : -tx.amountMinor,
                showSign: true,
                masked: hidden,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
        child: Column(
          children: <Widget>[
            Icon(
              PhosphorIconsRegular.receipt,
              size: AppSpacing.iconLg,
              color: colors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'No transactions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentLoading extends StatelessWidget {
  const _RecentLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.space24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RecentError extends StatelessWidget {
  const _RecentError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return AppCard(
      child: Row(
        children: <Widget>[
          Icon(PhosphorIconsRegular.warningCircle, color: colors.expense),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              'Could not load transactions.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
