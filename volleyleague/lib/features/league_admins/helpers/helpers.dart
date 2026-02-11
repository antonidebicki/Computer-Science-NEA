const List<String> seasonPlannerMonthNames = [
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

const List<String> seasonPlannerWeekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<double> seasonPlannerMatchesPerWeekOptions = [
  0.25,
  0.5,
  1,
  2,
  3,
];

DateTime seasonPlannerMaxEndDate(DateTime startDate) {
  return DateTime(startDate.year + 1, startDate.month, startDate.day);
}

String formatSeasonPlannerDate(DateTime date) {
  final month = seasonPlannerMonthNames[date.month - 1];
  return '${date.day} $month ${date.year}';
}

String buildSeasonName(DateTime startDate, DateTime endDate) {
  if (startDate.year == endDate.year) {
    return '${startDate.year} season';
  }
  return '${startDate.year}/${endDate.year} season';
}

bool isSeasonRangeValid(DateTime startDate, DateTime endDate) {
  if (endDate.isBefore(startDate)) {
    return false;
  }
  final maxEnd = seasonPlannerMaxEndDate(startDate);
  return !endDate.isAfter(maxEnd);
}

String matchesPerWeekTooltip({
  required List<double> options,
  required int index,
}) {
  final value = options[index];
  if (value == 0.5) {
    return 'Once every two weeks';
  }
  if (value == 0.25) {
    return 'Once every four weeks';
  }
  return '${value.toInt()} match${value == 1 ? '' : 'es'} per week';
}

int deriveWeeksBetweenMatches(double matchesPerWeekValue) {
  if (matchesPerWeekValue == 0.5) return 2;
  if (matchesPerWeekValue == 0.25) return 4;
  return 1;
}
