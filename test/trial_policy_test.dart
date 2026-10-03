import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/services/trial_policy.dart';

void main() {
  final start = DateTime.utc(2026, 10, 1, 9, 30);
  const day = Duration(days: 1);
  const second = Duration(seconds: 1);

  group('trial length', () {
    test('is 14 days', () => expect(TrialPolicy.durationDays, 14));

    test('expiry is exactly 14 days after the stored trialStartDate', () {
      expect(TrialPolicy.expiryOf(start), DateTime.utc(2026, 10, 15, 9, 30));
    });

    test('active at the start and on day 13', () {
      expect(TrialPolicy.evaluate(start, start), TrialStatus.active);
      expect(
          TrialPolicy.evaluate(start, start.add(day * 13)), TrialStatus.active);
    });

    test('active one second before 14 days', () {
      expect(TrialPolicy.evaluate(start, start.add(day * 14 - second)),
          TrialStatus.active);
    });

    test('expired at exactly 14 days', () {
      expect(TrialPolicy.evaluate(start, start.add(day * 14)),
          TrialStatus.expired);
    });

    test('expired one second after 14 days and long after', () {
      expect(TrialPolicy.evaluate(start, start.add(day * 14 + second)),
          TrialStatus.expired);
      expect(TrialPolicy.evaluate(start, start.add(day * 60)),
          TrialStatus.expired);
    });
  });

  group('validation', () {
    test('missing start date is invalid', () {
      expect(TrialPolicy.evaluate(null, start), TrialStatus.invalid);
    });

    test('start date far in the future is invalid', () {
      expect(
          TrialPolicy.evaluate(start.add(day * 2), start), TrialStatus.invalid);
    });

    test('small clock skew is tolerated', () {
      expect(
          TrialPolicy.evaluate(start.add(const Duration(minutes: 30)), start),
          TrialStatus.active);
    });
  });

  group('days remaining', () {
    test('counts down and never goes negative', () {
      expect(TrialPolicy.remainingDays(start, start), 14);
      expect(TrialPolicy.remainingDays(start, start.add(day)), 13);
      expect(TrialPolicy.remainingDays(start, start.add(day * 13)), 1);
      expect(TrialPolicy.remainingDays(start, start.add(day * 14 - second)), 1);
      expect(TrialPolicy.remainingDays(start, start.add(day * 14)), 0);
      expect(TrialPolicy.remainingDays(start, start.add(day * 20)), 0);
    });
  });

  group('logout / new account cannot restart the trial', () {
    test('the earlier start date always wins', () {
      final newerAccountStart = start.add(day * 3);
      expect(TrialPolicy.earliest(start, newerAccountStart), start);
      expect(TrialPolicy.earliest(newerAccountStart, start), start);
      expect(TrialPolicy.earliest(null, start), start);
      expect(TrialPolicy.earliest(start, null), start);
      expect(TrialPolicy.earliest(null, null), isNull);
    });

    test('a later account start does not extend the trial', () {
      final effective = TrialPolicy.earliest(start, start.add(day * 3));
      expect(TrialPolicy.evaluate(effective, start.add(day * 14)),
          TrialStatus.expired);
    });
  });
}
