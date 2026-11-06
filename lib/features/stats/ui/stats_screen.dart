import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/animated_money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/pill_tabs.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/gemini_advice_client.dart';
import '../data/stats_repository.dart';
import '../logic/advice_providers.dart';
import '../logic/stats_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _tab = 0;
  bool _hideAmounts = false;
  late DateTime _month = _currentMonth();

  static DateTime _currentMonth() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth => _month == _currentMonth();

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _showAiAdvice(StatsSummary summary) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const AlertDialog(
        title: Text('AI advice'),
        content: SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final AdviceResult result =
        await ref.read(geminiAdviceClientProvider).advise(summary);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(
          PhosphorIconsRegular.robot,
          color: context.colors.accent,
        ),
        title: const Text('AI advice'),
        content: SingleChildScrollView(
          child: Text(
            result.isOk
                ? result.text!
                : (result.error ??
                    'Could not get advice. Your stats still work offline.'),
          ),
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
    final AsyncValue<StatsSummary> stats = ref.watch(statsProvider(_month));

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
            Text(
              'Statistics',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _MonthSwitcher(
              label: _monthLabel(_month),
              canGoNext: !_isCurrentMonth,
              onPrevious: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
            const SizedBox(height: AppSpacing.space16),
            ...stats.when(
              data: (StatsSummary summary) => _content(context, summary),
              loading: () => const <Widget>[
                SkeletonBox(height: 150, radius: AppSpacing.radius20),
                SizedBox(height: AppSpacing.space16),
                SkeletonBox(height: 48, radius: AppSpacing.radiusPill),
                SizedBox(height: AppSpacing.space16),
                SkeletonBox(height: 280, radius: AppSpacing.radius20),
              ],
              error: (Object error, StackTrace stack) => <Widget>[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.space32),
                  child: Center(
                    child: Text(
                      'Could not load statistics.',
                      style: TextStyle(color: colors.expense),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, StatsSummary summary) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return <Widget>[
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Spent in ${monthName(summary.month)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: _hideAmounts ? 'Show amounts' : 'Hide amounts',
                  child: InkWell(
                    onTap: () => setState(() => _hideAmounts = !_hideAmounts),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space8),
                      child: Icon(
                        _hideAmounts
                            ? PhosphorIconsRegular.eyeSlash
                            : PhosphorIconsRegular.eye,
                        size: AppSpacing.iconMd,
                        color: colors.textSecondary,
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
                minor: summary.totalMinor,
                masked: _hideAmounts,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _TrendChip(summary: summary),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.space16),
      PillTabs(
        index: _tab,
        labels: const <String>['Category', 'Person', 'Month'],
        onChanged: (int index) => setState(() => _tab = index),
      ),
      const SizedBox(height: AppSpacing.space16),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey<int>(_tab),
          child: switch (_tab) {
            0 => _CategoryTab(summary: summary, hidden: _hideAmounts),
            1 => _PersonTab(summary: summary, hidden: _hideAmounts),
            _ => _MonthTab(summary: summary, hidden: _hideAmounts),
          },
        ),
      ),
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
                    onPressed: () => _showAiAdvice(summary),
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
    ];
  }

  String _monthLabel(DateTime month) {
    final bool sameYear = month.year == DateTime.now().year;
    return sameYear ? monthName(month) : '${monthName(month)} ${month.year}';
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Previous month',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              label,
              key: ValueKey<String>(label),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: canGoNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// "12% less than October" as a colored chip with a trend arrow.
class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);

    String text;
    IconData icon = Icons.remove;
    Color color = colors.textSecondary;

    if (summary.months.length < 2) {
      text = 'Start tracking to compare months.';
    } else {
      final MonthSpend previous = summary.months[summary.months.length - 2];
      final int current = summary.totalMinor;
      final int before = previous.amountMinor;

      if (current == 0) {
        text = 'No spending this month.';
      } else if (before == 0) {
        text = 'No spending in ${monthName(previous.month)}.';
      } else {
        final int percent = ((current - before).abs() / before * 100).round();
        if (current < before) {
          text = '$percent% less than ${monthName(previous.month)}';
          icon = Icons.trending_down;
          color = colors.income;
        } else if (current > before) {
          text = '$percent% more than ${monthName(previous.month)}';
          icon = Icons.trending_up;
          color = colors.expense;
        } else {
          text = 'Same as ${monthName(previous.month)}';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: AppSpacing.iconSm, color: color),
          const SizedBox(width: AppSpacing.space8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
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
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final List<CategorySpend> items = summary.categories;
    final int total = summary.totalMinor;

    return AppCard(
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double t, Widget? child) {
                    return CustomPaint(
                      size: const Size.square(190),
                      painter: _DonutPainter(
                        values: <double>[
                          for (final CategorySpend c in items)
                            c.amountMinor.toDouble(),
                        ],
                        colors: <Color>[
                          for (final CategorySpend c in items)
                            Color(c.category.colorValue),
                        ],
                        track: colors.barTrack,
                        stroke: 22,
                        progress: t,
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      formatMinor(total, masked: hidden),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          for (int i = 0; i < items.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space16),
            _LegendRow(
              item: items[i],
              share: total == 0 ? 0 : items[i].amountMinor / total,
              hidden: hidden,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.item,
    required this.share,
    required this.hidden,
  });

  final CategorySpend item;
  final double share;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Row(
      children: <Widget>[
        CategoryAvatar(category: item.category, size: 36),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(share * 100).round()}% of spending',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          formatMinor(item.amountMinor, masked: hidden),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.track,
    required this.stroke,
    required this.progress,
  });

  final List<double> values;
  final List<Color> colors;
  final Color track;
  final double stroke;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final double total = values.fold<double>(0, (double a, double b) => a + b);
    if (total <= 0) {
      return;
    }

    final double gap = values.length > 1 ? 0.05 : 0;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final double sweep = values[i] / total * math.pi * 2 * progress;
      final double drawn = math.max(0, sweep - gap);
      if (drawn > 0) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          drawn,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.butt
            ..color = colors[i],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.colors != colors ||
      old.track != track;
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
              fraction: max == 0 ? 0 : summary.persons[i].amountMinor / max,
              color: colors.accent,
              hidden: hidden,
              leading: Container(
                width: 36,
                height: 36,
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

  static String _compact(int minor) {
    final double major = minor / 100;
    if (major >= 1000) {
      return '${(major / 1000).toStringAsFixed(1)}k';
    }
    return major.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    if (summary.months.isEmpty) {
      return const _EmptyStats(message: 'No monthly data yet.');
    }
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    int max = 0;
    int sum = 0;
    int withData = 0;
    for (final MonthSpend month in summary.months) {
      if (month.amountMinor > max) {
        max = month.amountMinor;
      }
      if (month.amountMinor > 0) {
        sum += month.amountMinor;
        withData++;
      }
    }
    final int average = withData == 0 ? 0 : (sum / withData).round();
    const double chartHeight = 150;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: chartHeight + 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (int i = 0; i < summary.months.length; i++)
                  Expanded(
                    child: _Bar(
                      label: shortMonthName(summary.months[i].month),
                      valueLabel: hidden
                          ? '••'
                          : _compact(summary.months[i].amountMinor),
                      fraction: max == 0
                          ? 0
                          : summary.months[i].amountMinor / max,
                      maxHeight: chartHeight,
                      highlighted: i == summary.months.length - 1,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: <Widget>[
              Icon(
                PhosphorIconsRegular.calendarBlank,
                size: AppSpacing.iconSm,
                color: colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  withData == 0
                      ? 'No spending in the last ${summary.months.length} months.'
                      : 'Average ${formatMinor(average, masked: hidden)} '
                          'per month',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.maxHeight,
    required this.highlighted,
  });

  final String label;
  final String valueLabel;
  final double fraction;
  final double maxHeight;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final double target = math.max(4, fraction * maxHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          valueLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: highlighted ? colors.textPrimary : colors.textSecondary,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double h, Widget? child) {
            return Container(
              width: 26,
              height: h,
              decoration: BoxDecoration(
                color: highlighted
                    ? colors.accent
                    : colors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: highlighted ? colors.accent : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double v, Widget? child) {
              return LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: colors.barTrack,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
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
      child: SizedBox(
        width: double.infinity,
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
      ),
    );
  }
}
