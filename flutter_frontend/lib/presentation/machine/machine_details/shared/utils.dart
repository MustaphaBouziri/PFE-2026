class Utils {
  static String formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year.toString();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');

      return '$day $month $year $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  static String formatSearchableDate(dynamic dt) {
  if (dt == null) return '';

  final DateTime? dateTime = DateTime.tryParse(dt.toString());

  if (dateTime == null) return '';

  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  final monthName = months[dateTime.month - 1];
  return '$day $monthName ${dateTime.year} $day/$month/${dateTime.year} $day-$month-${dateTime.year}';
}
}
