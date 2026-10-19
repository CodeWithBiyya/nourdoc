import 'dart:convert';

/// One HTTP response, with a message taken from a string or a JSON body.
class HttpResult {
  final int statusCode;
  final String message;
  final bool reachedServer;

  const HttpResult({
    required this.statusCode,
    required this.message,
    required this.reachedServer,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  static const unreachable = HttpResult(
    statusCode: 0,
    message: 'The server could not be reached. Nothing was changed.',
    reachedServer: false,
  );

  factory HttpResult.fromResponse(int statusCode, String body) {
    return HttpResult(
      statusCode: statusCode,
      message: messageFromBody(body),
      reachedServer: true,
    );
  }
}

/// POST /plans/subscribe result. Errors keep the status code and the
/// backend message. The message is not used to decide what happened.
class SubscribeResult {
  final int statusCode;
  final String message;
  final bool reachedServer;
  final Map<String, dynamic>? data;

  const SubscribeResult({
    required this.statusCode,
    required this.message,
    required this.reachedServer,
    this.data,
  });

  bool get isSuccess => reachedServer && statusCode >= 200 && statusCode < 300;

  static const unreachable = SubscribeResult(
    statusCode: 0,
    message: 'The server could not be reached. The plan was not started.',
    reachedServer: false,
  );

  factory SubscribeResult.fromResponse(int statusCode, String body) {
    Map<String, dynamic>? data;
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final decoded = jsonDecode(body);
        final payload = successPayload(decoded);
        if (payload is Map) data = Map<String, dynamic>.from(payload);
      } catch (_) {}
    }

    var message = messageFromBody(body);
    if (message.isEmpty && (statusCode < 200 || statusCode >= 300)) {
      message = 'The plan was not started ($statusCode).';
    }

    return SubscribeResult(
      statusCode: statusCode,
      message: message,
      reachedServer: true,
      data: data,
    );
  }
}

/// Reads a backend message from plain text, a JSON string, or an object.
String messageFromBody(String body) {
  final raw = body.trim();
  if (raw.isEmpty) return '';

  try {
    final decoded = jsonDecode(raw);
    final message = _messageFromDecoded(decoded);
    if (message != null && message.isNotEmpty) return message;
    if (decoded is Map &&
        (decoded.containsKey('data') ||
            decoded.containsKey('message') ||
            decoded.containsKey('detail'))) {
      return '';
    }
    return raw;
  } catch (_) {
    return raw;
  }
}

/// Success bodies are `{ "data": <payload>, "message": ... }`.
/// The payload is what the rest of the app already reads.
dynamic successPayload(dynamic decoded) {
  if (decoded is Map && decoded.containsKey('data') && decoded['data'] != null) {
    return decoded['data'];
  }
  return decoded;
}

String? _messageFromDecoded(dynamic decoded) {
  if (decoded is String) {
    final text = decoded.trim();
    return text.isEmpty ? null : text;
  }

  if (decoded is Map) {
    for (final key in ['message', 'error', 'detail']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    if (decoded['response'] != null) {
      return _messageFromDecoded(decoded['response']);
    }
  }

  return null;
}
