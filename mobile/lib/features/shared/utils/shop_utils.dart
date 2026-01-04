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

bool isShopOpenNow(Map<String, dynamic>? openingHours) {
  if (openingHours == null) return false;

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
  if (todayHours == null) return false;

  final openStr = todayHours['open'] as String?;
  final closeStr = todayHours['close'] as String?;

  if (openStr == null || closeStr == null) return false;

  try {
    final openParts = openStr.split(':');
    final closeParts = closeStr.split(':');

    final openTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(openParts[0]),
      int.parse(openParts[1]),
    );

    final closeTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(closeParts[0]),
      int.parse(closeParts[1]),
    );

    return now.isAfter(openTime) && now.isBefore(closeTime);
  } catch (e) {
    return false;
  }
}
