import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/animated_money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/debt_repository.dart';
import '../logic/debt_providers.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  /// 0 = all, 1 = you owe, 2 = owed to you.
  int _filter = 0;

  void _openAdd(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AddDebtScreen(),
      ),
    );
  }

  void _openDetail(BuildContext context, int debtId) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => DebtDetailScreen(debtId: debtId),
      ),
    );
  }

  bool _matches(DebtSummary item) {
    return switch (_filter) {
      1 => item.debt.direction == DebtDirection.owed,
      2 => item.debt.direction == DebtDirection.lent,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AsyncValue<List<DebtSummary>> debts = ref.watch(debtsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(PhosphorIconsRegular.plus),
        label: const Text('Add debt'),
      ),
      body: SafeArea(
        bottom: false,
        child: debts.when(
          data: (List<DebtSummary> items) {
            final DebtOverview overview = DebtOverview.from(items);
            final List<DebtSummary> open = items
                .where((DebtSummary i) => !i.isSettled && _matches(i))
                .toList(growable: false);
            final List<DebtSummary> settled = items
                .where((DebtSummary i) => i.isSettled && _matches(i))
                .toList(growable: false);
            final int net = overview.owedToYouMinor - overview.youOweMinor;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space16,
                AppSpacing.space16,
                100,
              ),
              children: <Widget>[
                Text(
                  'Debts',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Money you owe and money owed to you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SummaryCard(
                        label: 'You owe',
                        icon: PhosphorIconsRegular.arrowUpRight,
                        amountMinor: overview.youOweMinor,
                        count: overview.youOweCount,
                        background: colors.debtOwed,
                        foreground: colors.debtOwedSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Owed to you',
                        icon: PhosphorIconsRegular.arrowDownLeft,
                        amountMinor: overview.owedToYouMinor,
                        count: overview.owedToYouCount,
                        background: colors.debtLentSurface,
                        foreground: colors.debtLent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space12),
                _NetLine(netMinor: net),
                const SizedBox(height: AppSpacing.space16),
                PillTabs(
                  index: _filter,
                  labels: const <String>['All', 'You owe', 'Owed to you'],
                  onChanged: (int i) => setState(() => _filter = i),
                ),
                const SizedBox(height: AppSpacing.space16),
                const SectionHeader(title: 'Open'),
                const SizedBox(height: AppSpacing.space8),
                if (open.isEmpty)
                  _EmptyOpen(
                    filtered: _filter != 0 && items.isNotEmpty,
                    onAdd: () => _openAdd(context),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < open.length; i++) ...<Widget>[
                          if (i > 0) Divider(height: 1, color: colors.outline),
                          _DebtRow(
                            item: open[i],
                            onTap: () => _openDetail(context, open[i].debt.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (settled.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.space24),
                  const SectionHeader(title: 'Settled'),
                  const SizedBox(height: AppSpacing.space8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < settled.length; i++) ...<Widget>[
                          if (i > 0) Divider(height: 1, color: colors.outline),
                          _DebtRow(
                            item: settled[i],
                            onTap: () =>
                                _openDetail(context, settled[i].debt.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => ListView(
            padding: AppSpacing.page,
            children: const <Widget>[
              SkeletonBox(height: 34, width: 120),
              SizedBox(height: AppSpacing.space24),
              SkeletonBox(height: 110, radius: AppSpacing.radius20),
              SizedBox(height: AppSpacing.space24),
              TransactionListSkeleton(),
            ],
          ),
          error: (Object error, StackTrace stack) => Center(
            child: Text(
              'Could not load debts.',
              style: TextStyle(color: colors.expense),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.icon,
    required this.amountMinor,
    required this.count,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final int amountMinor;
  final int count;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radius20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: AppSpacing.iconSm, color: foreground),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.8),
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
            child: AnimatedMoney(
              minor: amountMinor,
              style: theme.textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            count == 0
                ? 'No open debts'
                : '$count open ${count == 1 ? 'debt' : 'debts'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetLine extends StatelessWidget {
  const _NetLine({required this.netMinor});

  final int netMinor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Color color = netMinor > 0
        ? colors.income
        : netMinor < 0
            ? colors.expense
            : colors.textSecondary;

    return Row(
      children: <Widget>[
        Text(
          'Net position',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          formatMinor(netMinor, showSign: true),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _EmptyOpen extends StatelessWidget {
  const _EmptyOpen({required this.filtered, required this.onAdd});

  final bool filtered;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return AppCard(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
          child: Column(
            children: <Widget>[
              Icon(
                PhosphorIconsRegular.handCoins,
                size: AppSpacing.iconLg,
                color: colors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                filtered ? 'Nothing open in this view' : 'No open debts',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (!filtered) ...<Widget>[
                const SizedBox(height: AppSpacing.space12),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(PhosphorIconsRegular.plus),
                  label: const Text('Add debt'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.item, required this.onTap});

  final DebtSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final bool isOwed = item.debt.direction == DebtDirection.owed;
    final Color accent = isOwed ? colors.debtOwed : colors.debtLent;

    final DateTime? due = item.debt.dueDate;
    final DateTime today = DateTime.now();
    final bool overdue = !item.isSettled &&
        due != null &&
        DateTime(due.year, due.month, due.day)
            .isBefore(DateTime(today.year, today.month, today.day));

    final String subtitle = item.isSettled
        ? 'Settled · ${formatMinor(item.debt.principalMinor)}'
        : '${isOwed ? 'You owe' : 'Owes you'} · ${dueLabel(due)}';

    final bool showProgress = !item.isSettled && item.paidMinor > 0;
    final double progress = item.debt.principalMinor == 0
        ? 0
        : item.paidMinor / item.debt.principalMinor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isSettled
                        ? PhosphorIconsRegular.check
                        : isOwed
                            ? PhosphorIconsRegular.arrowUpRight
                            : PhosphorIconsRegular.arrowDownLeft,
                    size: AppSpacing.iconSm,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.debt.person,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overdue ? colors.expense : colors.textSecondary,
                          fontWeight:
                              overdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  formatMinor(
                    item.isSettled
                        ? item.debt.principalMinor
                        : item.outstandingMinor,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: item.isSettled ? colors.textSecondary : accent,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
            if (showProgress) ...<Widget>[
              const SizedBox(height: AppSpacing.space8),
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: colors.barTrack,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      '${(progress * 100).round()}% paid',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
