import 'dart:convert';

/// Success responses are `{ "data": <object or list>, "message": ... }`.
/// One level is removed so existing parsers keep reading the same payload.
/// `data: null` is left in place so a top-level message is still readable.
dynamic unwrapApiData(dynamic decoded) {
  if (decoded is Map && decoded.containsKey('data')) {
    final data = decoded['data'];
    if (data is Map || data is List) return data;
  }
  return decoded;
}

/// A short backend sentence is safe to show. SQL, stacks, and exception
/// class names are not.
bool isSafeUserSentence(String text) {
  final value = text.trim();
  if (value.isEmpty || value.length > 180) return false;
  final lower = value.toLowerCase();
  const blocked = [
    'exception',
    'psycopg',
    'sqlalchemy',
    'sql:',
    'insert into',
    'select ',
    'traceback',
    'stacktrace',
    'socketexception',
    'formatexception',
    'error during communication',
    'status code',
    '<html',
    'http://',
    'https://',
  ];
  for (final word in blocked) {
    if (lower.contains(word)) return false;
  }
  return true;
}

/// Reads `detail`, then `message`, and drops anything that is not a short sentence.
String? safeDetail(String body) {
  final raw = body.trim();
  if (raw.isEmpty) return null;

  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    decoded = raw;
  }

  String? text;
  if (decoded is String) text = decoded.trim();
  if (decoded is Map) {
    for (final key in ['detail', 'message']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        text = value.trim();
        break;
      }
    }
  }
  if (text == null || !isSafeUserSentence(text)) return null;
  return text;
}

/// Sentence for a known HTTP status when the body is not safe to show.
String safeUserMessage(
  int statusCode,
  String body, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final detail = safeDetail(body);
  if (detail != null) return detail;

  switch (statusCode) {
    case 401:
      return 'Your session has expired. Log in again.';
    case 402:
      return 'No active plan is available for this action.';
    case 404:
      return 'The requested record was not found.';
    case 409:
      return 'This conflicts with the current record.';
    case 400:
      return 'The information sent was not accepted.';
    case 0:
      return 'The server could not be reached. Nothing was changed.';
    default:
      if (statusCode >= 500) {
        return 'The server could not complete this. Try again.';
      }
      return fallback;
  }
}

/// Turns an exception into one sentence. The original text is not shown.
String safeErrorText(Object error) {
  final text = error.toString().trim();
  if (isSafeUserSentence(text)) return text;

  final code = RegExp(r'\b([45]\d\d)\b').firstMatch(text);
  if (code != null) {
    return safeUserMessage(int.parse(code.group(1)!), '');
  }

  final lower = text.toLowerCase();
  if (lower.contains('socket') ||
      lower.contains('no internet') ||
      lower.contains('clientexception')) {
    return 'No internet connection. Check your connection and try again.';
  }
  if (lower.contains('timeout')) {
    return 'The server took too long to respond. Try again.';
  }
  return 'Something went wrong. Please try again.';
}

/// A map or string from an API call, or [fallback] when it is not safe.
String shownApiText(
  dynamic value, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (value is Map) {
    for (final key in ['detail', 'message']) {
      final item = value[key];
      if (item is String && isSafeUserSentence(item)) return item.trim();
    }
  }
  if (value is String && isSafeUserSentence(value)) return value.trim();
  return fallback;
}
