import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/debt_repository.dart';
import '../logic/debt_providers.dart';
import 'add_debt_screen.dart';
import 'record_payment_sheet.dart';

class DebtDetailScreen extends ConsumerStatefulWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final int debtId;

  @override
  ConsumerState<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends ConsumerState<DebtDetailScreen> {
  DebtSummary? _item;
  bool _loading = true;
  bool _missing = false;
  bool _busy = false;

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
    final DebtSummary? item =
        await ref.read(debtRepositoryProvider).getById(widget.debtId);
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
    final DebtSummary? item = _item;
    if (item == null) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddDebtScreen(existing: item),
      ),
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _recordPayment() async {
    final DebtSummary? item = _item;
    if (item == null || item.isSettled) {
      return;
    }
    final bool saved = await showRecordPaymentSheet(
      context: context,
      debtId: item.debt.id,
      outstandingMinor: item.outstandingMinor,
    );
    if (saved && mounted) {
      await _reload();
    }
  }

  Future<void> _settleInFull() async {
    final DebtSummary? item = _item;
    if (item == null || item.isSettled) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Settle in full?'),
        content: Text(
          'Record a payment of ${formatMinor(item.outstandingMinor)} '
          'and mark this debt as settled.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(debtRepositoryProvider).addPayment(
            debtId: item.debt.id,
            amountMinor: item.outstandingMinor,
          );
      if (mounted) {
        await _reload();
      }
    } on DebtPaymentException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not settle the debt.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete debt?'),
        content: const Text(
          'This removes the debt and its payment history.',
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
    final DebtSummary? item = _item;
    if (item == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(debtRepositoryProvider).delete(item.debt.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the debt.')),
        );
      }
    }
  }

  Future<void> _deletePayment(DebtPayment payment) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Remove the ${formatMinor(payment.amountMinor)} payment?',
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
    try {
      await ref.read(debtRepositoryProvider).deletePayment(payment.id);
      if (mounted) {
        await _reload();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the payment.')),
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
        title: const Text('Debt'),
        actions: <Widget>[
          if (_item != null)
            IconButton(
              tooltip: 'Edit',
              onPressed: _busy ? null : _edit,
              icon: const Icon(PhosphorIconsRegular.pencilSimple),
            ),
          if (_item != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: _busy ? null : _confirmDelete,
              icon: const Icon(PhosphorIconsRegular.trash),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _missing || _item == null
                ? Center(
                    child: Text(
                      'Debt not found.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : _DetailBody(
                    item: _item!,
                    busy: _busy,
                    onRecordPayment: _recordPayment,
                    onSettle: _settleInFull,
                    onDeletePayment: _deletePayment,
                  ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.item,
    required this.busy,
    required this.onRecordPayment,
    required this.onSettle,
    required this.onDeletePayment,
  });

  final DebtSummary item;
  final bool busy;
  final VoidCallback onRecordPayment;
  final VoidCallback onSettle;
  final ValueChanged<DebtPayment> onDeletePayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Debt debt = item.debt;
    final bool isOwed = debt.direction == DebtDirection.owed;
    final Color accent = isOwed ? colors.debtOwed : colors.debtLent;
    final String directionLabel = isOwed ? 'You owe' : 'Owes you';
    final double progress = debt.principalMinor == 0
        ? 0
        : (item.paidMinor / debt.principalMinor).clamp(0.0, 1.0);
    final AsyncValue<List<DebtPayment>> payments =
        ref.watch(debtPaymentsProvider(debt.id));
    final String? note = debt.note?.trim();

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
              _DebtHero(
                accent: accent,
                amountMinor: item.outstandingMinor,
                person: debt.person,
                directionLabel: directionLabel,
                isOwed: isOwed,
                settled: item.isSettled,
                dueText: dueLabel(debt.dueDate),
              ),
              const SizedBox(height: AppSpacing.space16),
              AppCard(
                radius: AppSpacing.radius20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.isSettled ? 'Settled' : 'Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colors.barTrack,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      '${formatMinor(item.paidMinor)} of '
                      '${formatMinor(debt.principalMinor)} paid',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              AppCard(
                radius: AppSpacing.radius20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    _MetaRow(
                      icon: isOwed
                          ? PhosphorIconsRegular.arrowUpRight
                          : PhosphorIconsRegular.arrowDownLeft,
                      label: 'Direction',
                      value: directionLabel,
                      iconColor: accent,
                      valueColor: accent,
                    ),
                    Divider(height: 1, color: colors.outline),
                    _MetaRow(
                      icon: PhosphorIconsRegular.coins,
                      label: 'Principal',
                      value: formatMinor(debt.principalMinor),
                    ),
                    Divider(height: 1, color: colors.outline),
                    _MetaRow(
                      icon: PhosphorIconsRegular.calendarBlank,
                      label: 'Due date',
                      value: debt.dueDate == null
                          ? 'No due date'
                          : longDate(debt.dueDate!),
                    ),
                    if (note != null && note.isNotEmpty) ...<Widget>[
                      Divider(height: 1, color: colors.outline),
                      _MetaRow(
                        icon: PhosphorIconsRegular.notePencil,
                        label: 'Note',
                        value: note,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              Text(
                'Payments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              payments.when(
                data: (List<DebtPayment> items) {
                  if (items.isEmpty) {
                    return AppCard(
                      radius: AppSpacing.radius20,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space8,
                        ),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              PhosphorIconsRegular.handCoins,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.space8),
                            Text(
                              'No payments yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return AppCard(
                    radius: AppSpacing.radius20,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < items.length; i++) ...<Widget>[
                          if (i > 0)
                            Divider(height: 1, color: colors.outline),
                          _PaymentRow(
                            payment: items[i],
                            onDelete: () => onDeletePayment(items[i]),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.space16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object error, StackTrace stack) => Text(
                  'Could not load payments.',
                  style: TextStyle(color: colors.expense),
                ),
              ),
            ],
          ),
        ),
        if (!item.isSettled)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(top: BorderSide(color: colors.outline)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space12,
                AppSpacing.space16,
                AppSpacing.space16,
              ),
              child: Column(
                children: <Widget>[
                  PrimaryButton(
                    label: 'Record payment',
                    icon: PhosphorIconsRegular.handCoins,
                    onPressed: busy ? null : onRecordPayment,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: busy ? null : onSettle,
                      child: const Text('Settle in full'),
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

class _DebtHero extends StatelessWidget {
  const _DebtHero({
    required this.accent,
    required this.amountMinor,
    required this.person,
    required this.directionLabel,
    required this.isOwed,
    required this.settled,
    required this.dueText,
  });

  final Color accent;
  final int amountMinor;
  final String person;
  final String directionLabel;
  final bool isOwed;
  final bool settled;
  final String dueText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radius28),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOwed
                  ? PhosphorIconsRegular.arrowUpRight
                  : PhosphorIconsRegular.arrowDownLeft,
              color: accent,
              size: AppSpacing.iconLg,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              settled ? 'Settled' : directionLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            formatMinor(amountMinor),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            person,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            dueText,
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Color tint = iconColor ?? colors.textSecondary;

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
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSpacing.iconMd, color: tint),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: valueColor ?? colors.textPrimary,
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

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.onDelete,
  });

  final DebtPayment payment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final String? note = payment.note?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.income.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.check,
              size: AppSpacing.iconSm,
              color: colors.income,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  formatMinor(payment.amountMinor),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  note == null || note.isEmpty
                      ? longDate(payment.paidAt)
                      : '${longDate(payment.paidAt)} · $note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete payment',
            onPressed: onDelete,
            icon: Icon(
              PhosphorIconsRegular.trash,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
