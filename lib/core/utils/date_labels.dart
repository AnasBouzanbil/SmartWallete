const List<String> _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String monthName(DateTime date) => _months[date.month - 1];

String shortMonthName(DateTime date) => monthName(date).substring(0, 3);

String shortDate(DateTime date, {DateTime? now}) {
  final DateTime today = _dateOnly(now ?? DateTime.now());
  final DateTime day = _dateOnly(date);
  final int diff = today.difference(day).inDays;

  if (diff == 0) {
    return 'Today';
  }
  if (diff == 1) {
    return 'Yesterday';
  }
  if (diff > 1 && diff < 7) {
    return _weekdays[day.weekday - 1];
  }
  return '${day.day} ${shortMonthName(day)}';
}

String longDate(DateTime date, {DateTime? now}) {
  final DateTime today = _dateOnly(now ?? DateTime.now());
  final DateTime day = _dateOnly(date);
  if (today == day) {
    return 'Today';
  }
  return '${day.day} ${shortMonthName(day)} ${day.year}';
}

String dueLabel(DateTime? dueDate, {DateTime? now}) {
  if (dueDate == null) {
    return 'No due date';
  }
  final DateTime today = _dateOnly(now ?? DateTime.now());
  final DateTime due = _dateOnly(dueDate);
  final int days = due.difference(today).inDays;

  if (days == 0) {
    return 'Due today';
  }
  if (days == 1) {
    return 'Due tomorrow';
  }
  if (days > 1) {
    return 'Due in $days days';
  }
  if (days == -1) {
    return 'Overdue by 1 day';
  }
  return 'Overdue by ${days.abs()} days';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
