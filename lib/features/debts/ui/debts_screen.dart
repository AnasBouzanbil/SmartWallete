import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_card.dart';
import '../data/debt_repository.dart';
import '../logic/debt_providers.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                .where((DebtSummary item) => !item.isSettled)
                .toList(growable: false);
            final List<DebtSummary> settled = items
                .where((DebtSummary item) => item.isSettled)
                .toList(growable: false);

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
                        amountMinor: overview.youOweMinor,
                        background: colors.debtOwed,
                        foreground: colors.debtOwedSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Owed to you',
                        amountMinor: overview.owedToYouMinor,
                        background: colors.debtLentSurface,
                        foreground: colors.debtLent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space24),
                Text(
                  'Open',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                if (open.isEmpty)
                  AppCard(
                    radius: AppSpacing.radius20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space16,
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            PhosphorIconsRegular.handCoins,
                            size: AppSpacing.iconLg,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.space8),
                          Text(
                            'No open debts',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          TextButton.icon(
                            onPressed: () => _openAdd(context),
                            icon: const Icon(PhosphorIconsRegular.plus),
                            label: const Text('Add debt'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  AppCard(
                    radius: AppSpacing.radius20,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < open.length; i++) ...<Widget>[
                          if (i > 0)
                            Divider(height: 1, color: colors.outline),
                          _DebtRow(
                            item: open[i],
                            onTap: () =>
                                _openDetail(context, open[i].debt.id),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (settled.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.space24),
                  Text(
                    'Settled',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  AppCard(
                    radius: AppSpacing.radius20,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < settled.length; i++) ...<Widget>[
                          if (i > 0)
                            Divider(height: 1, color: colors.outline),
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
          loading: () => const Center(child: CircularProgressIndicator()),
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
    required this.amountMinor,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int amountMinor;
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
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            formatMinor(amountMinor),
            style: theme.textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final String subtitle = item.isSettled
        ? 'Settled · ${formatMinor(item.debt.principalMinor)}'
        : '${isOwed ? 'You owe' : 'Owes you'} · ${dueLabel(item.debt.dueDate)}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
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
                      color: colors.textSecondary,
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
      ),
    );
  }
}
