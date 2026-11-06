import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/money/money.dart';
import '../../../core/storage/receipt_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/transaction_repository.dart';
import '../logic/transaction_providers.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = TransactionType.expense,
    this.existing,
  });

  final TransactionType initialType;
  final TransactionWithCategory? existing;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _person = TextEditingController();
  final TextEditingController _note = TextEditingController();

  late TransactionType _type;
  late DateTime _date;
  int? _categoryId;
  Category? _lockedCategory;
  XFile? _pickedReceipt;
  String? _receiptPath;
  String? _amountError;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final TransactionWithCategory? existing = widget.existing;
    if (existing != null) {
      final Transaction tx = existing.transaction;
      _type = tx.type;
      _date = tx.date;
      _categoryId = tx.categoryId;
      _lockedCategory = existing.category;
      _receiptPath = tx.imagePath;
      _person.text = tx.person ?? '';
      _note.text = tx.note ?? '';
      _amount.text = _formatAmountInput(tx.amountMinor);
    } else {
      _type = widget.initialType;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _person.dispose();
    _note.dispose();
    super.dispose();
  }

  CategoryKind get _kind => _type == TransactionType.expense
      ? CategoryKind.expense
      : CategoryKind.income;

  String _formatAmountInput(int amountMinor) {
    final int whole = amountMinor ~/ 100;
    final int frac = amountMinor % 100;
    if (frac == 0) {
      return '$whole';
    }
    return '$whole.${frac.toString().padLeft(2, '0')}';
  }

  void _setType(TransactionType type) {
    if (type == _type) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _categoryId = null;
      if (_lockedCategory != null && _lockedCategory!.kind != _kind) {
        _lockedCategory = null;
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file != null) {
        setState(() {
          _pickedReceipt = file;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo picker.')),
        );
      }
    }
  }

  Future<void> _chooseReceiptSource() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(PhosphorIconsRegular.camera),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.image),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) {
      await _pickReceipt(source);
    }
  }

  List<Category> _matchingCategories(List<Category> all) {
    final List<Category> matching = all
        .where((Category c) => c.kind == _kind)
        .toList(growable: true);
    final Category? locked = _lockedCategory;
    if (locked != null &&
        locked.kind == _kind &&
        matching.every((Category c) => c.id != locked.id)) {
      matching.insert(0, locked);
    }
    return matching;
  }

  Future<void> _save() async {
    final Money? amount = Money.tryParse(_amount.text);
    if (amount == null || amount.isZero) {
      setState(() => _amountError = 'Enter an amount.');
      return;
    }
    setState(() {
      _amountError = null;
      _saving = true;
    });

    try {
      final List<Category> categories =
          ref.read(categoriesProvider).asData?.value ?? const <Category>[];
      final List<Category> matching = _matchingCategories(categories);
      final int? categoryId =
          _categoryId ?? (matching.isEmpty ? null : matching.first.id);
      if (categoryId == null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No category available.')),
        );
        return;
      }

      String? imagePath = _receiptPath;
      if (_pickedReceipt != null) {
        final String? oldPath = _receiptPath;
        imagePath = await ReceiptStore.save(_pickedReceipt!);
        if (_isEditing && oldPath != null && oldPath != imagePath) {
          await ReceiptStore.delete(oldPath);
        }
      }

      final TransactionRepository repo =
          ref.read(transactionRepositoryProvider);

      if (_isEditing) {
        await repo.update(
          id: widget.existing!.transaction.id,
          type: _type,
          amountMinor: amount.minor,
          categoryId: categoryId,
          date: _date,
          person: _person.text,
          note: _note.text,
          imagePath: imagePath,
        );
      } else {
        final Account account = await ref.read(defaultAccountProvider.future);
        await repo.add(
          type: _type,
          amountMinor: amount.minor,
          categoryId: categoryId,
          accountId: account.id,
          date: _date,
          person: _person.text,
          note: _note.text,
          imagePath: imagePath,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the transaction.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final AsyncValue<List<Category>> categories = ref.watch(categoriesProvider);
    final List<Category> matching =
        _matchingCategories(categories.asData?.value ?? const <Category>[]);
    final int? selectedId = _categoryId ??
        (matching.isEmpty ? null : matching.first.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(PhosphorIconsRegular.x),
        ),
        title: Text(_isEditing ? 'Edit transaction' : 'New transaction'),
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
            _TypeSwitch(type: _type, onChanged: _setType),
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
              autofocus: !_isEditing,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: _type == TransactionType.expense
                    ? colors.expense
                    : colors.income,
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
            Text(
              'Category',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            categories.when(
              data: (_) => Wrap(
                spacing: AppSpacing.space8,
                runSpacing: AppSpacing.space8,
                children: matching
                    .map(
                      (Category category) => _CategoryChip(
                        category: category,
                        selected: category.id == selectedId,
                        onTap: () =>
                            setState(() => _categoryId = category.id),
                      ),
                    )
                    .toList(growable: false),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.space16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (Object error, StackTrace stack) => Text(
                'Could not load categories.',
                style: TextStyle(color: colors.expense),
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            TextField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Person (optional)',
                prefixIcon: Icon(PhosphorIconsRegular.user),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _QuickDates(
              date: _date,
              onPick: (DateTime d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.space8),
            _DateField(date: _date, onTap: _pickDate),
            const SizedBox(height: AppSpacing.space12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Add a note',
                prefixIcon: Icon(PhosphorIconsRegular.notePencil),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            _ReceiptField(
              picked: _pickedReceipt,
              existingPath: _pickedReceipt == null ? _receiptPath : null,
              onTap: _chooseReceiptSource,
            ),
            const SizedBox(height: AppSpacing.space24),
            PrimaryButton(
              label: _saving
                  ? 'Saving…'
                  : _isEditing
                      ? 'Save changes'
                      : _type == TransactionType.expense
                          ? 'Save expense'
                          : 'Save income',
              icon: PhosphorIconsRegular.check,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({required this.type, required this.onChanged});

  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    Widget item(String label, TransactionType value) {
      final bool selected = value == type;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? (value == TransactionType.expense
                      ? colors.expense
                      : colors.accent)
                  : Colors.transparent,
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
          item('Expense', TransactionType.expense),
          item('Income', TransactionType.income),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;

    return Material(
      color: selected ? colors.accent : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                categoryIcon(category.iconKey),
                size: AppSpacing.iconSm,
                color: selected
                    ? colors.onAccent
                    : Color(category.colorValue),
              ),
              const SizedBox(width: AppSpacing.space4),
              Text(
                category.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onAccent : colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radius16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space16,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                PhosphorIconsRegular.calendarBlank,
                color: context.colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.space12),
              Text('Date', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                longDate(date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({
    required this.picked,
    required this.existingPath,
    required this.onTap,
  });

  final XFile? picked;
  final String? existingPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final bool hasPhoto = picked != null ||
        (existingPath != null && existingPath!.trim().isNotEmpty);

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radius16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius12),
                child: picked != null
                    ? Image.file(
                        File(picked!.path),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      )
                    : existingPath != null && existingPath!.trim().isNotEmpty
                        ? FutureBuilder<String>(
                            future: ReceiptStore.absolutePath(existingPath!),
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<String> snapshot,
                            ) {
                              if (!snapshot.hasData) {
                                return _receiptPlaceholder(colors);
                              }
                              final File file = File(snapshot.data!);
                              if (!file.existsSync()) {
                                return _receiptPlaceholder(colors);
                              }
                              return Image.file(
                                file,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : _receiptPlaceholder(colors),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Receipt',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      hasPhoto ? 'Photo attached' : 'Attach photo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIconsRegular.camera,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptPlaceholder(AppColorSet colors) {
    return Container(
      width: 44,
      height: 44,
      color: colors.surface,
      child: Icon(
        PhosphorIconsRegular.receipt,
        color: colors.textSecondary,
      ),
    );
  }
}

/// One-tap "Today" / "Yesterday" shortcuts above the date field.
class _QuickDates extends StatelessWidget {
  const _QuickDates({required this.date, required this.onPick});

  final DateTime date;
  final ValueChanged<DateTime> onPick;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final AppColorSet colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(days: 1));

    Widget chip(String label, DateTime value) {
      final bool selected = _sameDay(date, value);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.space8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: selected ? colors.onAccent : colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) {
            HapticFeedback.selectionClick();
            onPick(value);
          },
        ),
      );
    }

    return Row(
      children: <Widget>[
        chip('Today', now),
        chip('Yesterday', yesterday),
      ],
    );
  }
}
