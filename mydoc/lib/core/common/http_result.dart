import 'dart:convert';

import 'api_envelope.dart';

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

  /// Paid subscribe returns this instead of an entitlement id.
  /// The checkout page itself is not opened here.
  bool get isStripeCheckout {
    final url = data?['checkout_url']?.toString().trim() ?? '';
    return url.isNotEmpty;
  }

  static const unreachable = SubscribeResult(
    statusCode: 0,
    message: 'The server could not be reached. The plan was not started.',
    reachedServer: false,
  );

  factory SubscribeResult.fromResponse(int statusCode, String body) {
    Map<String, dynamic>? data;
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final decoded = unwrapApiData(jsonDecode(body));
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
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
/// SQL, stacks, and raw JSON are left blank so the caller can use its own sentence.
String messageFromBody(String body) {
  return safeDetail(body) ?? '';
}
