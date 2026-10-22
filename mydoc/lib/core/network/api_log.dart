import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// One client for every `http.get`, `http.post`, `http.put`, and `http.delete`.
/// Install it with [runWithClient] around `runApp`. Do not construct [http.Client]
/// inside this class: that would call this factory again.
class LoggingClient extends http.BaseClient {
  LoggingClient() : _inner = IOClient();

  final IOClient _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final copy = http.Request(request.method, request.url)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..bodyBytes = bytes;
    request.headers.forEach((key, value) {
      copy.headers[key] = value;
    });

    _write('API --> ${copy.method} ${copy.url}');
    copy.headers.forEach((key, value) {
      _write('API     $key: ${_mask(key, value)}');
    });
    if (bytes.isNotEmpty) {
      _write('API     body: ${_bodyText(bytes)}');
    }

    try {
      final response = await _inner.send(copy);
      final responseBytes = await response.stream.toBytes();
      _write('API <-- ${response.statusCode} ${copy.method} ${copy.url}');
      if (responseBytes.isNotEmpty) {
        _write('API     body: ${_bodyText(responseBytes)}');
      }
      return http.StreamedResponse(
        http.ByteStream.fromBytes(responseBytes),
        response.statusCode,
        contentLength: responseBytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (error) {
      _write('API <-- FAILED ${copy.method} ${copy.url}');
      _write('API     $error');
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

String _mask(String key, String value) {
  if (key.toLowerCase() != 'authorization') return value;
  if (value.length <= 16) return '***';
  return '${value.substring(0, 12)}...';
}

String _bodyText(List<int> bytes) {
  if (bytes.length > 4000) {
    return '<${bytes.length} bytes>';
  }
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return '<${bytes.length} bytes>';
  }
}

void _write(String message) {
  const size = 800;
  for (var start = 0; start < message.length; start += size) {
    final end = start + size > message.length ? message.length : start + size;
    debugPrint(message.substring(start, end));
  }
}
