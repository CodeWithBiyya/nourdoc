import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../common/http_result.dart';
import 'app_exceptions.dart';
import 'base_api_services.dart';

class NetworkApiService extends BaseApiService {
  @override
  Future getGetResponse(String url, String token) async {
    dynamic responseJson;
    try {
      final response = await http.get(
          Uri.parse(url),
          headers: {"Authorization": "Bearer $token"}
      ).timeout(const Duration(seconds: 15)); // 🔹 Increased timeout

      responseJson = returnResponse(response);

    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } on http.ClientException {
      throw FetchDataException('Communication Error');
    }

    return responseJson;
  }

  @override
  Future getPostApiResponse(String url, Map<String, String> data, String? token) async {
    Map<String, String> headersz = {};
    if (token != null) {
      headersz = {"Authorization": "Bearer $token"};
    }
    dynamic responseJson;
    try {
      Response response = await http.post(
        Uri.parse(url),
        body: data,
        headers: headersz,
      ).timeout(const Duration(seconds: 15));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  // 🔹 Updated logic to prevent generic popups on empty data
  dynamic returnResponse(http.Response response) {
    final decoded = _decode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return successPayload(decoded);

      case 404:
      // A missing record stays a 404 map so lists stay empty and
      // entitlement stays "no plan". The server sentence is in detail.
        final missing = _serverText(decoded) ?? 'No data available';
        return {
          "custom_status": 404,
          "message": missing,
          "detail": missing,
          "code": decoded is Map ? decoded['code'] : null,
          "data": []
        };

      case 409:
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          if (map['message'] == null && map['detail'] is String) {
            map['message'] = map['detail'];
          }
          return map;
        }
        return decoded;

      case 401:
        throw UnauthorisedException(_serverText(decoded) ?? 'status code 401');

      default:
        throw FetchDataException(
          _serverText(decoded) ??
              'Error occurred with status code ${response.statusCode}',
        );
    }
  }

  dynamic _decode(String body) {
    final raw = body.trim();
    if (raw.isEmpty) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  String? _serverText(dynamic decoded) {
    if (decoded is Map) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
    return null;
  }

  @override
  Future getPostApiResponseWithoutParam(String url) async {
    dynamic responseJson;
    try {
      Response response = await http.post(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        },
      ).timeout(const Duration(seconds: 30));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  @override
  Future getPostApiResponseRaw(String url, dynamic data, String? token) async {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    var bodyData = encoder.convert(data);

    Map<String, String> headers = {
      "Accept": "application/json",
      "Content-Type": "application/json"
    };
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    dynamic responseJson;
    try {
      Response response = await http.post(
        Uri.parse(url),
        body: bodyData,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  // @override
  // Future putApiResponseRaw(String url, data, String token) async {
  //   dynamic responseJson;
  //   try {
  //     Response response = await http.put(
  //       Uri.parse(url),
  //       headers: {"Authorization": "Bearer $token"},
  //       body: data,
  //     ).timeout(const Duration(seconds: 15));
  //
  //     responseJson = returnResponse(response);
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //
  //   return responseJson;
  // }

  @override
  Future putApiResponseRaw(String url, dynamic data, String? token) async {
    dynamic responseJson;
    try {
      final response = await http.put(
        Uri.parse(url),
        body: jsonEncode(data), // 🚩 DATA KO JSON BANANA LAZMI HAI
        headers: {
          'Content-Type': 'application/json', // 🚩 YEH HEADER HONA CHAHIYE
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);
    } catch (e) {
      rethrow;
    }
    return responseJson;
  }
}