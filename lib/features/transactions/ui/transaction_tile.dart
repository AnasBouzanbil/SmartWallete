import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../../core/database/app_database.dart';
import '../../../core/money/display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/category_avatar.dart';
import '../data/transaction_repository.dart';
import 'transaction_detail_screen.dart';
import 'transaction_title.dart';

/// One transaction row, shared by Home and the full list.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    this.hidden = false,
    this.showDate = true,
  });

  final TransactionWithCategory item;
  final bool hidden;

  /// Home shows the date in the subtitle; the grouped list already has day
  /// headers, so it turns this off.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorSet colors = context.colors;
    final Transaction tx = item.transaction;
    final bool isIncome = tx.type == TransactionType.income;
    final String title = transactionTitle(item);
    final String? person = tx.person?.trim();
    final bool hasReceipt =
        tx.imagePath != null && tx.imagePath!.trim().isNotEmpty;

    final List<String> subtitle = <String>[item.category.name];
    if (person != null && person.isNotEmpty && person != title) {
      subtitle.add(person);
    }
    if (showDate) {
      subtitle.add(shortDate(tx.date));
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                TransactionDetailScreen(transactionId: tx.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: <Widget>[
            CategoryAvatar(category: item.category),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasReceipt) ...<Widget>[
                        const SizedBox(width: AppSpacing.space4),
                        Icon(
                          PhosphorIconsRegular.receipt,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle.join(' · '),
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
                isIncome ? tx.amountMinor : -tx.amountMinor,
                showSign: true,
                masked: hidden,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isIncome ? colors.income : colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
