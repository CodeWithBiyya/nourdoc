import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../app_exceptions.dart';
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
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);

      case 404:
      // 🚩 KEY CHANGE: Instead of throwing an error, return a custom map
      // This stops the "Communication Error" popup from appearing on Dashboard
        return {
          "custom_status": 404,
          "message": "No data available",
          "data": []
        };

      case 409:
        return jsonDecode(response.body);

      case 401:
      // Unauthorized logic remains
        throw UnauthorisedException('status code 401');

      default:
      // Generic error for everything else
        throw FetchDataException(
          'Error occurred with status code ${response.statusCode}',
        );
    }
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