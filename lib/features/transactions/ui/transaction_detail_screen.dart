import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/storage/receipt_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/transaction_repository.dart';
import '../logic/transaction_providers.dart';
import 'add_transaction_screen.dart';
import 'receipt_image.dart';
import 'transaction_title.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  TransactionWithCategory? _item;
  bool _loading = true;
  bool _missing = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _missing = false;
    });
    final TransactionWithCategory? item = await ref
        .read(transactionRepositoryProvider)
        .getById(widget.transactionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _item = item;
      _loading = false;
      _missing = item == null;
    });
  }

  Future<void> _edit() async {
    final TransactionWithCategory? item = _item;
    if (item == null) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddTransactionScreen(
          existing: item,
        ),
      ),
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This removes the transaction from your balance and history.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: context.colors.expense),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _delete();
  }

  Future<void> _delete() async {
    final TransactionWithCategory? item = _item;
    if (item == null) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await ReceiptStore.delete(item.transaction.imagePath);
      await ref
          .read(transactionRepositoryProvider)
          .delete(item.transaction.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the transaction.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: const Text('Transaction'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _missing || _item == null
                ? Center(
                    child: Text(
                      'Transaction not found.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : _DetailBody(
                    item: _item!,
                    deleting: _deleting,
                    onEdit: _edit,
                    onDelete: _confirmDelete,
                  ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.item,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionWithCategory item;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Transaction tx = item.transaction;
    final bool isIncome = tx.type == TransactionType.income;
    final Color amountColor = isIncome ? colors.income : colors.expense;
    final String typeLabel = isIncome ? 'Income' : 'Expense';
    final String title = transactionTitle(item);
    final String? person = tx.person?.trim();
    final String? note = tx.note?.trim();
    final bool hasReceipt =
        tx.imagePath != null && tx.imagePath!.trim().isNotEmpty;

    final List<_DetailRowData> rows = <_DetailRowData>[
      _DetailRowData(
        icon: PhosphorIconsRegular.calendarBlank,
        label: 'Date',
        value: longDate(tx.date),
      ),
      _DetailRowData(
        icon: isIncome
            ? PhosphorIconsRegular.arrowDownLeft
            : PhosphorIconsRegular.arrowUpRight,
        label: 'Type',
        value: typeLabel,
        valueColor: amountColor,
      ),
      _DetailRowData(
        icon: categoryIcon(item.category.iconKey),
        label: 'Category',
        value: item.category.name,
        iconColor: Color(item.category.colorValue),
      ),
      if (person != null && person.isNotEmpty)
        _DetailRowData(
          icon: PhosphorIconsRegular.user,
          label: 'Person',
          value: person,
        ),
      if (note != null && note.isNotEmpty)
        _DetailRowData(
          icon: PhosphorIconsRegular.notePencil,
          label: 'Note',
          value: note,
        ),
    ];

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space8,
              AppSpacing.space16,
              AppSpacing.space24,
            ),
            children: <Widget>[
              _AmountHero(
                amountMinor: isIncome ? tx.amountMinor : -tx.amountMinor,
                amountColor: amountColor,
                category: item.category,
                typeLabel: typeLabel,
                title: title,
                isIncome: isIncome,
              ),
              const SizedBox(height: AppSpacing.space16),
              AppCard(
                radius: AppSpacing.radius20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < rows.length; i++) ...<Widget>[
                      if (i > 0) Divider(height: 1, color: colors.outline),
                      _DetailRow(data: rows[i]),
                    ],
                  ],
                ),
              ),
              if (hasReceipt) ...<Widget>[
                const SizedBox(height: AppSpacing.space16),
                AppCard(
                  radius: AppSpacing.radius20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              PhosphorIconsRegular.receipt,
                              size: AppSpacing.iconMd,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Text(
                            'Receipt',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      ReceiptImage(
                        imagePath: tx.imagePath!,
                        height: 220,
                        borderRadius: AppSpacing.radius16,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              top: BorderSide(color: colors.outline),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space12,
              AppSpacing.space16,
              AppSpacing.space16,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: deleting ? null : onDelete,
                    icon: const Icon(PhosphorIconsRegular.trash),
                    label: Text(deleting ? 'Deleting…' : 'Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.expense,
                      side: BorderSide(
                        color: colors.expense.withValues(alpha: 0.45),
                      ),
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Edit',
                    icon: PhosphorIconsRegular.pencilSimple,
                    onPressed: deleting ? null : onEdit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.amountMinor,
    required this.amountColor,
    required this.category,
    required this.typeLabel,
    required this.title,
    required this.isIncome,
  });

  final int amountMinor;
  final Color amountColor;
  final Category category;
  final String typeLabel;
  final String title;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space32,
      ),
      decoration: BoxDecoration(
        color: amountColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radius28),
        border: Border.all(
          color: amountColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: <Widget>[
          CategoryAvatar(category: category, size: 64),
          const SizedBox(height: AppSpacing.space16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isIncome
                      ? PhosphorIconsRegular.arrowDownLeft
                      : PhosphorIconsRegular.arrowUpRight,
                  size: AppSpacing.iconSm,
                  color: amountColor,
                ),
                const SizedBox(width: AppSpacing.space4),
                Text(
                  typeLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            formatMinor(amountMinor, showSign: true),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (title != category.name) ...<Widget>[
            const SizedBox(height: AppSpacing.space8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          Text(
            category.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRowData {
  const _DetailRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.data});

  final _DetailRowData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Color iconColor = data.iconColor ?? colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: AppSpacing.iconMd,
              color: iconColor,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: data.valueColor ?? colors.textPrimary,
                    fontWeight: FontWeight.w600,
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
