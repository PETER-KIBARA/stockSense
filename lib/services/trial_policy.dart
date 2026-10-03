enum TrialStatus { active, expired, invalid }

class TrialPolicy {
  static const int durationDays = 14;
  static const Duration duration = Duration(days: durationDays);
  static const Duration maxClockSkew = Duration(hours: 1);

  /// The trial ends exactly [duration] after [start].
  static DateTime expiryOf(DateTime start) => start.add(duration);

  static TrialStatus evaluate(DateTime? start, DateTime now) {
    if (start == null) return TrialStatus.invalid;
    if (start.isAfter(now.add(maxClockSkew))) return TrialStatus.invalid;
    return now.difference(start) >= duration
        ? TrialStatus.expired
        : TrialStatus.active;
  }

  static int remainingDays(DateTime start, DateTime now) {
    final left = expiryOf(start).difference(now);
    if (left <= Duration.zero) return 0;
    final days = (left.inSeconds / Duration.secondsPerDay).ceil();
    return days > durationDays ? durationDays : days;
  }

  /// A start date can only move earlier, never later.
  static DateTime? earliest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}
