import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/utils/friendly_error.dart';

void main() {
  test('maps permission and connection errors to plain language', () {
    expect(
        friendlyError(Exception(
            '[cloud_firestore/permission-denied] Missing or insufficient permissions.')),
        contains('not allowed'));
    expect(
        friendlyError(Exception(
            '[cloud_firestore/unavailable] The service is currently unavailable.')),
        contains('No connection'));
  });

  test('keeps our own readable messages and strips the wrappers', () {
    expect(
        friendlyError(Exception(
            'Failed to upload image: Exception: That photo is too large. Please choose a smaller one.')),
        'That photo is too large. Please choose a smaller one.');
  });

  test('never leaks technical text', () {
    expect(friendlyError(StateError('boom {x}')),
        'Something went wrong. Please try again.');
  });
}
