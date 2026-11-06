import '../../../core/money/display.dart';
import '../../../core/utils/date_labels.dart';
import 'stats_repository.dart';

/// Builds a privacy-safe prompt payload from stats aggregates only.
///
/// Never includes person names, notes, or receipt paths.
String buildAdvicePrompt(StatsSummary summary) {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln(
    'You are a concise personal-finance coach for a private wallet app.',
  );
  buffer.writeln(
    'Give 3 short practical tips in plain language as bullet points.',
  );
  buffer.writeln(
    'Use only the aggregates below. Do not invent transactions or people.',
  );
  buffer.writeln('Currency amounts are already formatted.');
  buffer.writeln();
  buffer.writeln('Month: ${monthName(summary.month)} ${summary.month.year}');
  buffer.writeln('Total spent: ${formatMinor(summary.totalMinor)}');

  if (summary.categories.isEmpty) {
    buffer.writeln('No spending categories this month.');
  } else {
    buffer.writeln('Top categories:');
    final int limit =
        summary.categories.length < 5 ? summary.categories.length : 5;
    for (int i = 0; i < limit; i++) {
      final CategorySpend item = summary.categories[i];
      final int percent = summary.totalMinor == 0
          ? 0
          : ((item.amountMinor / summary.totalMinor) * 100).round();
      buffer.writeln(
        '- ${item.category.name}: ${formatMinor(item.amountMinor)} ($percent%)',
      );
    }
  }

  if (summary.months.length >= 2) {
    final MonthSpend current = summary.months.last;
    final MonthSpend previous = summary.months[summary.months.length - 2];
    buffer.writeln(
      'Vs previous month (${monthName(previous.month)}): '
      '${formatMinor(previous.amountMinor)} then, '
      '${formatMinor(current.amountMinor)} now.',
    );
  }

  buffer.writeln();
  buffer.writeln('Reply with tips only. No preamble.');
  return buffer.toString();
}

/// True when [text] looks like it contains person-level labels we must not send.
/// Used in tests to guard the payload builder.
bool advicePromptLooksSafe(String prompt) {
  final String lower = prompt.toLowerCase();
  return !lower.contains('person:') &&
      !lower.contains('people:') &&
      !lower.contains('receipt') &&
      !lower.contains('note:');
}
