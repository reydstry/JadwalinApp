class TimeHelper {
  TimeHelper._();

  static String formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    final formattedHours = hours.toString().padLeft(2, '0');
    final formattedMinutes = minutes.toString().padLeft(2, '0');

    return '$formattedHours:$formattedMinutes';
  }

  static String formatRange(int start, int end) {
    return '${formatMinutes(start)} - ${formatMinutes(end)}';
  }
}
