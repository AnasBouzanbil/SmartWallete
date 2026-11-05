import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';

/// Temporary screen used to preview the design system before real screens
/// exist. Shows colors, type, buttons, inputs, cards and states in light
/// and dark mode. Not part of the final feature set.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key, this.onToggleTheme});

  final VoidCallback? onToggleTheme;

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Preview'),
        actions: [
          IconButton(
            tooltip: 'Toggle light / dark',
            onPressed: widget.onToggleTheme,
            icon: const Icon(PhosphorIconsRegular.circleHalfTilt),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          _SectionTitle('Colors'),
          const _ColorSwatches(),
          const SizedBox(height: AppSpacing.space16),

          _SectionTitle('Typography'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Headline', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.space8),
                Text('Title', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.space8),
                Text('Body text', style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'Secondary text',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),

          _SectionTitle('Amounts'),
          AppCard(
            child: const Column(
              children: [
                AmountText(1250.5, type: AmountType.income),
                SizedBox(height: AppSpacing.space8),
                AmountText(89.99, type: AmountType.expense),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),

          _SectionTitle('Buttons'),
          PrimaryButton(
            label: 'Primary action',
            icon: PhosphorIconsRegular.plus,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.space8),
          PrimaryButton(label: 'Disabled', onPressed: null),
          const SizedBox(height: AppSpacing.space8),
          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
          const SizedBox(height: AppSpacing.space8),
          TextButton(onPressed: () {}, child: const Text('Text button')),
          const SizedBox(height: AppSpacing.space16),

          _SectionTitle('Inputs'),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: '0.00',
              prefixIcon: Icon(PhosphorIconsRegular.coins),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),

          _SectionTitle('Card'),
          AppCard(
            onTap: () {},
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.receipt),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Groceries', style: theme.textTheme.titleMedium),
                      Text(
                        'Food',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const AmountText(42.75, type: AmountType.expense),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),

          _SectionTitle('Empty state'),
          AppCard(
            child: EmptyState(
              icon: PhosphorIconsRegular.wallet,
              title: 'No transactions yet',
              message: 'Add your first income or expense to get started.',
            ),
          ),
          const SizedBox(height: AppSpacing.space32),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (int i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.wallet),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.handCoins),
            label: 'Debts',
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chartPieSlice),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final Map<String, Color> swatches = {
      'accent': colors.accent,
      'income': colors.income,
      'expense': colors.expense,
      'surface': colors.surface,
      'surfaceAlt': colors.surfaceAlt,
      'outline': colors.outline,
    };

    return AppCard(
      child: Wrap(
        spacing: AppSpacing.space12,
        runSpacing: AppSpacing.space12,
        children: swatches.entries
            .map(
              (MapEntry<String, Color> e) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSpacing.space32,
                    height: AppSpacing.space32,
                    decoration: BoxDecoration(
                      color: e.value,
                      borderRadius: BorderRadius.circular(AppSpacing.radius12),
                      border: Border.all(color: colors.outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(e.key, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
