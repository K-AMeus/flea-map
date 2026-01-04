String getTodayOpeningHours(Map<String, dynamic>? openingHours) {
  if (openingHours == null) return 'Hours not available';

  final now = DateTime.now();
  const dayNames = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final today = dayNames[now.weekday - 1];

  final todayHours = openingHours[today];
  if (todayHours == null) return 'Closed today';

  final open = todayHours['open'];
  final close = todayHours['close'];

  if (open == null || close == null) return 'Closed today';

  return 'open today: $open - $close';
}
