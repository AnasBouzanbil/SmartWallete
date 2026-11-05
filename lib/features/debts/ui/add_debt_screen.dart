import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/debt_repository.dart';
import '../logic/debt_providers.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({
    super.key,
    this.initialDirection = DebtDirection.owed,
    this.existing,
  });

  final DebtDirection initialDirection;
  final DebtSummary? existing;

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _person = TextEditingController();
  final TextEditingController _note = TextEditingController();

  late DebtDirection _direction;
  DateTime? _dueDate;
  String? _amountError;
  String? _personError;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final DebtSummary? existing = widget.existing;
    if (existing != null) {
      final Debt debt = existing.debt;
      _direction = debt.direction;
      _dueDate = debt.dueDate;
      _person.text = debt.person;
      _note.text = debt.note ?? '';
      _amount.text = _formatAmountInput(debt.principalMinor);
    } else {
      _direction = widget.initialDirection;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _person.dispose();
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

  Future<void> _pickDueDate() async {
    final DateTime initial = _dueDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _clearDueDate() {
    setState(() => _dueDate = null);
  }

  Future<void> _save() async {
    final String person = _person.text.trim();
    final Money? amount = Money.tryParse(_amount.text);
    String? amountError;
    String? personError;

    if (person.isEmpty) {
      personError = 'Enter a person.';
    }
    if (amount == null || amount.isZero) {
      amountError = 'Enter an amount.';
    }

    if (personError != null || amountError != null) {
      setState(() {
        _personError = personError;
        _amountError = amountError;
      });
      return;
    }

    setState(() {
      _personError = null;
      _amountError = null;
      _saving = true;
    });

    try {
      final DebtRepository repo = ref.read(debtRepositoryProvider);
      if (_isEditing) {
        await repo.update(
          id: widget.existing!.debt.id,
          person: person,
          direction: _direction,
          principalMinor: amount!.minor,
          dueDate: _dueDate,
          note: _note.text,
        );
      } else {
        await repo.add(
          person: person,
          direction: _direction,
          principalMinor: amount!.minor,
          dueDate: _dueDate,
          note: _note.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
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
          const SnackBar(content: Text('Could not save the debt.')),
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
          icon: const Icon(PhosphorIconsRegular.x),
        ),
        title: Text(_isEditing ? 'Edit debt' : 'New debt'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space8,
            AppSpacing.space16,
            AppSpacing.space24,
          ),
          children: <Widget>[
            _DirectionSwitch(
              direction: _direction,
              onChanged: (DebtDirection value) {
                setState(() => _direction = value);
              },
            ),
            const SizedBox(height: AppSpacing.space24),
            Text(
              'Amount',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '${appCurrency.symbol} ',
                prefixStyle: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
                hintText: '0.00',
                hintStyle: theme.textTheme.displaySmall?.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.5),
                ),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            TextField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Person',
                prefixIcon: const Icon(PhosphorIconsRegular.user),
                errorText: _personError,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _DueDateField(
              dueDate: _dueDate,
              onPick: _pickDueDate,
              onClear: _dueDate == null ? null : _clearDueDate,
            ),
            const SizedBox(height: AppSpacing.space12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a note',
                prefixIcon: Icon(PhosphorIconsRegular.notePencil),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            PrimaryButton(
              label: _saving
                  ? 'Saving…'
                  : _isEditing
                      ? 'Save changes'
                      : 'Save debt',
              icon: PhosphorIconsRegular.check,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionSwitch extends StatelessWidget {
  const _DirectionSwitch({
    required this.direction,
    required this.onChanged,
  });

  final DebtDirection direction;
  final ValueChanged<DebtDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    Widget item(String label, DebtDirection value) {
      final bool selected = value == direction;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space12,
            ),
            decoration: BoxDecoration(
              color: selected ? colors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? colors.onAccent : colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        children: <Widget>[
          item('You owe', DebtDirection.owed),
          item('Owed to you', DebtDirection.lent),
        ],
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.dueDate,
    required this.onPick,
    this.onClear,
  });

  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radius16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
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
              Expanded(
                child: Text(
                  'Due date',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                dueDate == null ? 'Optional' : longDate(dueDate!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (onClear != null) ...<Widget>[
                const SizedBox(width: AppSpacing.space8),
                IconButton(
                  tooltip: 'Clear due date',
                  onPressed: onClear,
                  icon: const Icon(PhosphorIconsRegular.x),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
