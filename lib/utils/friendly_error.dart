/// Turns exceptions into short messages a shop owner can act on.
String friendlyError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  final code = RegExp(r'\[[a-z_]+/([a-z-]+)\]').firstMatch(raw)?.group(1);
  switch (code) {
    case 'permission-denied':
      return 'That action is not allowed on this account.';
    case 'unavailable':
    case 'network-request-failed':
    case 'deadline-exceeded':
      return 'No connection right now. Check your internet and try again.';
    case 'resource-exhausted':
    case 'quota-exceeded':
      return 'The service is busy at the moment. Please try again shortly.';
    case 'unauthenticated':
      return 'Your session has expired. Return to the home page and start again.';
    case 'not-found':
      return 'That item no longer exists. Refresh and try again.';
  }

  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('xmlhttprequest error') ||
      lower.contains('network error')) {
    return 'No connection right now. Check your internet and try again.';
  }

  // Firestore rejecting an over-size document (usually a large photo).
  if (lower.contains('longer than') && lower.contains('bytes')) {
    return 'That photo is too large. Please choose a smaller one.';
  }

  // Our own messages are already readable: use the innermost one.
  const marker = 'Exception: ';
  final index = raw.lastIndexOf(marker);
  final inner = index >= 0 ? raw.substring(index + marker.length).trim() : '';
  if (inner.isNotEmpty &&
      inner.length <= 140 &&
      !inner.contains('[') &&
      !inner.contains('{')) {
    return inner;
  }

  return fallback;
}
