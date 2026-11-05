import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/money/display.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/debt_repository.dart';
import '../logic/debt_providers.dart';

Future<bool> showRecordPaymentSheet({
  required BuildContext context,
  required int debtId,
  required int outstandingMinor,
}) async {
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: RecordPaymentSheet(
        debtId: debtId,
        outstandingMinor: outstandingMinor,
      ),
    ),
  );
  return saved == true;
}

class RecordPaymentSheet extends ConsumerStatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.debtId,
    required this.outstandingMinor,
  });

  final int debtId;
  final int outstandingMinor;

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();

  late DateTime _paidAt = DateTime.now();
  String? _amountError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amount.text = _formatAmountInput(widget.outstandingMinor);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String _formatAmountInput(int amountMinor) {
    final int whole = amountMinor ~/ 100;
    final int frac = amountMinor % 100;
    if (frac == 0) {
      return '$whole';
    }
    return '$whole.${frac.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _paidAt = picked);
    }
  }

  Future<void> _save() async {
    final Money? amount = Money.tryParse(_amount.text);
    if (amount == null || amount.isZero) {
      setState(() => _amountError = 'Enter an amount.');
      return;
    }
    if (amount.minor > widget.outstandingMinor) {
      setState(() => _amountError = 'Cannot be more than the amount left.');
      return;
    }

    setState(() {
      _amountError = null;
      _saving = true;
    });

    try {
      await ref.read(debtRepositoryProvider).addPayment(
            debtId: widget.debtId,
            amountMinor: amount.minor,
            paidAt: _paidAt,
            note: _note.text,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on DebtPaymentException catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the payment.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space16,
          AppSpacing.space16,
          AppSpacing.space16,
          AppSpacing.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outline,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Record payment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '${formatMinor(widget.outstandingMinor)} left',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '${appCurrency.symbol} ',
                prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Material(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radius16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                    vertical: AppSpacing.space16,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        PhosphorIconsRegular.calendarBlank,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      const Text('Paid on'),
                      const Spacer(),
                      Text(
                        longDate(_paidAt),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(PhosphorIconsRegular.notePencil),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Save payment',
              icon: PhosphorIconsRegular.check,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
