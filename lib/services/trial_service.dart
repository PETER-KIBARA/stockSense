import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'trial_policy.dart';

export 'trial_policy.dart';

class TrialService {
  static const String _startKey = 'trial_start_ms';
  static const String _legacyKey = 'first_launch_date';
  static const int trialDurationDays = TrialPolicy.durationDays;

  static Future<DateTime?> _storedStart() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_startKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> _persistStart(DateTime start) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_startKey);
    final existing =
        ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    final earliest = TrialPolicy.earliest(existing, start);
    if (earliest != null) {
      await prefs.setInt(_startKey, earliest.millisecondsSinceEpoch);
    }
  }

  /// Earliest of the browser-remembered start and the account's start.
  static Future<DateTime?> _effectiveStart() async => TrialPolicy.earliest(
      await _storedStart(), AuthService.currentUser?.trialStartDate);

  /// Status of the current session. Non-trial (email) accounts are never gated.
  static Future<TrialStatus> currentStatus() async {
    if (!AuthService.isTrialSession) return TrialStatus.active;
    return TrialPolicy.evaluate(await _effectiveStart(), DateTime.now());
  }

  static Future<bool> isTrialExpired() async =>
      (await currentStatus()) != TrialStatus.active;

  static Future<DateTime> getFirstLaunchDate() async =>
      (await _effectiveStart()) ?? DateTime.now();

  static Future<int> getRemainingDays() async {
    final start = await _effectiveStart();
    if (start == null) return TrialPolicy.durationDays;
    return TrialPolicy.remainingDays(start, DateTime.now());
  }

  /// True when this browser already used up a full trial.
  static Future<bool> isTrialUsed() async =>
      TrialPolicy.evaluate(await _storedStart(), DateTime.now()) ==
      TrialStatus.expired;

  /// Remember the current start date on this browser (survives logout).
  static Future<void> markTrialUsed() async {
    final start = await _effectiveStart();
    if (start != null) await _persistStart(start);
  }

  /// "Sign Out" during an active trial: keep the account and the start date.
  static Future<void> leaveTrial() => markTrialUsed();

  /// Start or resume the trial. Validates the start date before access.
  static Future<TrialStatus> beginTrial() async {
    final stored = await _storedStart();

    // A trial already remembered on this browser never starts over.
    if (stored != null) {
      final s = TrialPolicy.evaluate(stored, DateTime.now());
      if (s != TrialStatus.active) {
        if (AuthService.isTrialSession) await AuthService.signOut();
        return s;
      }
    }

    final user = await AuthService.startTrial(resumeStart: stored);
    if (user == null) return TrialStatus.invalid;

    final start = (await _effectiveStart()) ?? DateTime.now();
    final status = TrialPolicy.evaluate(start, DateTime.now());
    if (status != TrialStatus.invalid) await _persistStart(start);
    if (status != TrialStatus.active) await AuthService.signOut();
    return status;
  }

  /// Development/testing only.
  static Future<void> resetTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_startKey);
    await prefs.remove(_legacyKey);
  }
}
