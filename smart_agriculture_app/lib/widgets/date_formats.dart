class DateFormats {
  DateFormats._();

  static const List<String> _months = [
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

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String current() {
    return pretty(DateTime.now());
  }

  static String pretty(DateTime dt) {
    return '${_days[dt.weekday - 1]}, ${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  static String short(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]}, ${dt.year}';
  }

  static String timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return short(dt);
    } catch (_) {
      return iso;
    }
  }
}
