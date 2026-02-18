extension DateTimeExtension on DateTime {
  DateTime toWib() {
    // If it's already UTC, add 7 hours.
    // Use toUtc() first to ensure we have a baseline.
    return toUtc().add(const Duration(hours: 7));
  }
}
