import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_avatar.dart';
import '../data/stats_repository.dart';
import '../logic/stats_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _tab = 0;
  bool _hideAmounts = false;

  void _showAiAdvice() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(
          PhosphorIconsRegular.robot,
          color: context.colors.accent,
        ),
        title: const Text('AI advice'),
        content: const Text(
          'Personalised spending tips are coming soon. Your data stays on '
          'this phone and only totals will be shared when this feature is '
          'enabled.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AsyncValue<StatsSummary> stats = ref.watch(currentStatsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: stats.when(
          data: (StatsSummary summary) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space16,
              AppSpacing.space24,
            ),
            children: <Widget>[
              Text(
                'Statistics',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Spent in ${monthName(summary.month)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(
                            () => _hideAmounts = !_hideAmounts,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.space4),
                            child: Icon(
                              _hideAmounts
                                  ? PhosphorIconsRegular.eyeSlash
                                  : PhosphorIconsRegular.eye,
                              size: AppSpacing.iconMd,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      formatMinor(
                        summary.totalMinor,
                        masked: _hideAmounts,
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      _comparisonLabel(summary),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              _PillTabs(
                index: _tab,
                labels: const <String>['Category', 'Person', 'Month'],
                onChanged: (int index) => setState(() => _tab = index),
              ),
              const SizedBox(height: AppSpacing.space16),
              if (_tab == 0)
                _CategoryTab(summary: summary, hidden: _hideAmounts)
              else if (_tab == 1)
                _PersonTab(summary: summary, hidden: _hideAmounts)
              else
                _MonthTab(summary: summary, hidden: _hideAmounts),
              const SizedBox(height: AppSpacing.space16),
              if (summary.topCategory != null)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            PhosphorIconsRegular.sparkle,
                            color: colors.accent,
                            size: AppSpacing.iconMd,
                          ),
                          const SizedBox(width: AppSpacing.space8),
                          Expanded(
                            child: Text(
                              '${summary.topCategory!.category.name} is '
                              '${(summary.topShare * 100).round()}% of your '
                              'spending.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Want tips to cut it?',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showAiAdvice,
                            icon: const Icon(
                              PhosphorIconsRegular.robot,
                              size: AppSpacing.iconSm,
                            ),
                            label: const Text('Ask AI'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        PhosphorIconsRegular.chartPieSlice,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Text(
                          'Add some expenses to see your spending insights.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) => Center(
            child: Text(
              'Could not load statistics.',
              style: TextStyle(color: colors.expense),
            ),
          ),
        ),
      ),
    );
  }

  String _comparisonLabel(StatsSummary summary) {
    if (summary.months.length < 2) {
      return 'Start tracking to compare months.';
    }
    final MonthSpend previous = summary.months[summary.months.length - 2];
    final int current = summary.totalMinor;
    final int before = previous.amountMinor;

    if (current == 0) {
      return 'No spending yet this month.';
    }
    if (before == 0) {
      return 'No spending in ${monthName(previous.month)}.';
    }
    final int percent = ((current - before).abs() / before * 100).round();
    if (current < before) {
      return '$percent% less than ${monthName(previous.month)}';
    }
    if (current > before) {
      return '$percent% more than ${monthName(previous.month)}';
    }
    return 'Same as ${monthName(previous.month)}';
  }
}

class _PillTabs extends StatelessWidget {
  const _PillTabs({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: i == index ? colors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusPill,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: i == index
                          ? colors.accent
                          : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.summary, required this.hidden});

  final StatsSummary summary;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (summary.categories.isEmpty) {
      return const _EmptyStats(message: 'No expenses this month.');
    }
    final int max = summary.categories.first.amountMinor;
    return AppCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < summary.categories.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space16),
            _SpendRow(
              label: summary.categories[i].category.name,
              amountMinor: summary.categories[i].amountMinor,
              fraction: max == 0
                  ? 0
                  : summary.categories[i].amountMinor / max,
              color: Color(summary.categories[i].category.colorValue),
              hidden: hidden,
              leading: CategoryAvatar(
                category: summary.categories[i].category,
                size: 34,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonTab extends StatelessWidget {
  const _PersonTab({required this.summary, required this.hidden});

  final StatsSummary summary;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (summary.persons.isEmpty) {
      return const _EmptyStats(message: 'No people tagged this month.');
    }
    final AppColorSet colors = context.colors;
    final int max = summary.persons.first.amountMinor;
    return AppCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < summary.persons.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space16),
            _SpendRow(
              label: summary.persons[i].person,
              amountMinor: summary.persons[i].amountMinor,
              fraction:
                  max == 0 ? 0 : summary.persons[i].amountMinor / max,
              color: colors.accent,
              hidden: hidden,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.user,
                  size: AppSpacing.iconSm,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthTab extends StatelessWidget {
  const _MonthTab({required this.summary, required this.hidden});

  final StatsSummary summary;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    if (summary.months.isEmpty) {
      return const _EmptyStats(message: 'No monthly data yet.');
    }
    final AppColorSet colors = context.colors;
    int max = 0;
    for (final MonthSpend month in summary.months) {
      if (month.amountMinor > max) {
        max = month.amountMinor;
      }
    }
    return AppCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < summary.months.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space16),
            _SpendRow(
              label: monthName(summary.months[i].month),
              amountMinor: summary.months[i].amountMinor,
              fraction: max == 0
                  ? 0
                  : summary.months[i].amountMinor / max,
              color: i == summary.months.length - 1
                  ? colors.accent
                  : colors.debtLent,
              hidden: hidden,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsRegular.calendarBlank,
                  size: AppSpacing.iconSm,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpendRow extends StatelessWidget {
  const _SpendRow({
    required this.label,
    required this.amountMinor,
    required this.fraction,
    required this.color,
    required this.hidden,
    required this.leading,
  });

  final String label;
  final int amountMinor;
  final double fraction;
  final Color color;
  final bool hidden;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            leading,
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              formatMinor(amountMinor, masked: hidden),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: 6,
            backgroundColor: colors.barTrack,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
        child: Column(
          children: <Widget>[
            Icon(
              PhosphorIconsRegular.chartPieSlice,
              size: AppSpacing.iconLg,
              color: colors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
