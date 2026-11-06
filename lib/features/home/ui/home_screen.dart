import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/animated_money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/logic/auth_state.dart';
import '../../debts/data/debt_repository.dart';
import '../../debts/logic/debt_providers.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/logic/transaction_providers.dart';
import '../../transactions/ui/add_transaction_screen.dart';
import '../../transactions/ui/transaction_tile.dart';
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
    HapticFeedback.lightImpact();
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
    final AppColorSet colors = context.colors;
    final AuthState auth = ref.watch(authControllerProvider);
    final DateTime now = DateTime.now();
    final DateTime month = DateTime(now.year, now.month);
    final DateTime previousMonth = DateTime(now.year, now.month - 1);

    final AsyncValue<int> net = ref.watch(netMinorProvider);
    final AsyncValue<MonthlyTotals> totals = ref.watch(
      monthlyTotalsProvider(month),
    );
    final AsyncValue<MonthlyTotals> previousTotals = ref.watch(
      monthlyTotalsProvider(previousMonth),
    );
    final AsyncValue<List<TransactionWithCategory>> recent = ref.watch(
      recentTransactionsProvider,
    );
    final AsyncValue<List<DebtSummary>> debts = ref.watch(debtsProvider);

    final int totalMinor =
        majorToMinor(auth.startingBalance) + (net.asData?.value ?? 0);
    final MonthlyTotals monthTotals =
        totals.asData?.value ?? MonthlyTotals.zero;
    final MonthlyTotals lastMonthTotals =
        previousTotals.asData?.value ?? MonthlyTotals.zero;
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
              greeting: _greeting(now),
              onLock: () => ref.read(authControllerProvider.notifier).lock(),
            ),
            const SizedBox(height: AppSpacing.space24),
            _BalanceCard(
              totalMinor: totalMinor,
              incomeMinor: monthTotals.incomeMinor,
              expenseMinor: monthTotals.expenseMinor,
              monthLabel: monthName(month),
              hidden: _hideAmounts,
              onToggle: () => setState(() => _hideAmounts = !_hideAmounts),
            ),
            const SizedBox(height: AppSpacing.space16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickAction(
                    label: 'Expense',
                    icon: PhosphorIconsRegular.plus,
                    iconColor: colors.expense,
                    background: colors.surface,
                    textColor: colors.textPrimary,
                    onTap: () => _openAdd(context, TransactionType.expense),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: _QuickAction(
                    label: 'Income',
                    icon: PhosphorIconsRegular.plus,
                    iconColor: colors.onAccent,
                    background: colors.accent,
                    textColor: colors.onAccent,
                    onTap: () => _openAdd(context, TransactionType.income),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),
            _MonthPace(
              spentMinor: monthTotals.expenseMinor,
              lastMonthSpentMinor: lastMonthTotals.expenseMinor,
              lastMonthLabel: monthName(previousMonth),
              hidden: _hideAmounts,
            ),
            const SizedBox(height: AppSpacing.space24),
            const SectionHeader(title: 'Debts'),
            const SizedBox(height: AppSpacing.space8),
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
            const SizedBox(height: AppSpacing.space16),
            SectionHeader(
              title: 'Recent',
              actionLabel: 'See all',
              onAction: () => _openAllTransactions(context),
            ),
            const SizedBox(height: AppSpacing.space4),
            recent.when(
              data: (List<TransactionWithCategory> items) {
                if (items.isEmpty) {
                  return _EmptyRecent(
                    onAdd: () => _openAdd(context, TransactionType.expense),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < items.length; i++) ...<Widget>[
                        if (i > 0) Divider(height: 1, color: colors.outline),
                        TransactionTile(item: items[i], hidden: _hideAmounts),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const TransactionListSkeleton(),
              error: (Object error, StackTrace stack) => _RecentError(
                onRetry: () => ref.invalidate(recentTransactionsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting(DateTime now) {
    final int h = now.hour;
    if (h < 5) {
      return 'Good night';
    }
    if (h < 12) {
      return 'Good morning';
    }
    if (h < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.greeting,
    required this.onLock,
  });

  final String name;
  final String greeting;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty ? 'W' : trimmed.substring(0, 1).toUpperCase();

    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: colors.accent.withValues(alpha: 0.5)),
          ),
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
                greeting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                trimmed.isEmpty ? 'My wallet' : trimmed,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Lock wallet',
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
    required this.monthLabel,
    required this.hidden,
    required this.onToggle,
  });

  final int totalMinor;
  final int incomeMinor;
  final int expenseMinor;
  final String monthLabel;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Color ink = colors.onAccent;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(AppSpacing.radius28),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -48,
            top: -48,
            child: _Blob(size: 170, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            right: 36,
            bottom: -70,
            child: _Blob(size: 130, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
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
                    Semantics(
                      button: true,
                      label: hidden ? 'Show amounts' : 'Hide amounts',
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onToggle();
                        },
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.space8),
                          child: Icon(
                            hidden
                                ? PhosphorIconsRegular.eyeSlash
                                : PhosphorIconsRegular.eye,
                            size: AppSpacing.iconMd,
                            color: ink.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedMoney(
                    minor: totalMinor,
                    masked: hidden,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  'This month · $monthLabel',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ink.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _FlowPill(
                        icon: PhosphorIconsRegular.arrowDownLeft,
                        label: 'Income',
                        text: formatMinor(incomeMinor, masked: hidden),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: _FlowPill(
                        icon: PhosphorIconsRegular.arrowUpRight,
                        label: 'Spent',
                        text: formatMinor(expenseMinor, masked: hidden),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FlowPill extends StatelessWidget {
  const _FlowPill({
    required this.icon,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color ink = context.colors.onAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radius16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: ink),
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: ink.withValues(alpha: 0.7),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
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
    required this.iconColor,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
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
              Icon(icon, size: AppSpacing.iconMd, color: iconColor),
              const SizedBox(width: AppSpacing.space8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spending so far this month, shown against last month's full total.
class _MonthPace extends StatelessWidget {
  const _MonthPace({
    required this.spentMinor,
    required this.lastMonthSpentMinor,
    required this.lastMonthLabel,
    required this.hidden,
  });

  final int spentMinor;
  final int lastMonthSpentMinor;
  final String lastMonthLabel;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final bool hasBaseline = lastMonthSpentMinor > 0;
    final double ratio =
        hasBaseline ? spentMinor / lastMonthSpentMinor : 0;
    final bool over = ratio > 1;
    final Color barColor = over ? colors.expense : colors.accent;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                PhosphorIconsRegular.sparkle,
                size: AppSpacing.iconMd,
                color: colors.accent,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  hasBaseline
                      ? (over
                          ? 'Already above $lastMonthLabel’s spending'
                          : 'You’ve used ${(ratio * 100).round()}% of '
                              '$lastMonthLabel’s spending')
                      : 'Spent ${formatMinor(spentMinor, masked: hidden)} so far this month',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasBaseline) ...<Widget>[
            const SizedBox(height: AppSpacing.space12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: ratio.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double value, Widget? child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: colors.barTrack,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              '${formatMinor(spentMinor, masked: hidden)} of '
              '${formatMinor(lastMonthSpentMinor, masked: hidden)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMinor(amountMinor, masked: hidden),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
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

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
        child: Center(
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
              const SizedBox(height: AppSpacing.space12),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(PhosphorIconsRegular.plus),
                label: const Text('Add your first expense'),
              ),
            ],
          ),
        ),
      ),
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
