// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// class EntitlementApiService {
//   static const String baseUrl =
//       'https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com';

//   Future<void> activateTrial({
//     required String doctorId,
//   }) async {
//     final url = Uri.parse(
//       '$baseUrl/entitlements/activate-trial',
//     );

//     final response = await http.post(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'doctor_id': doctorId,
//         'accepted_terms': true,
//       }),
//     );

//     debugPrint('Activate Trial Status: ${response.statusCode}');
//     debugPrint('Activate Trial Response: ${response.body}');

//     if (response.statusCode < 200 ||
//         response.statusCode >= 300) {
//       throw Exception(
//         'Failed to activate trial: ${response.statusCode}',
//       );
//     }
//   }
// }

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EntitlementApiService {
  static const String baseUrl =
      'https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com';

  // =========================================================
  // ACTIVATE TRIAL
  // =========================================================

  Future<Map<String, dynamic>> activateTrial({
    required String doctorId,
    bool acceptedTerms = true,
  }) async {
    final url = Uri.parse(
      '$baseUrl/entitlements/activate-trial',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'doctor_id': doctorId,
        'accepted_terms': acceptedTerms,
      }),
    );

    debugPrint(
      'Activate Trial Status: ${response.statusCode}',
    );

    debugPrint(
      'Activate Trial Response: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to activate trial: ${response.statusCode}',
      );
    }

    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  // =========================================================
  // ENTITLEMENT STATUS
  // =========================================================

  Future<Map<String, dynamic>> getEntitlementStatus({
    required String doctorId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/entitlements/status',
    ).replace(
      queryParameters: {
        'doctor_id': doctorId,
      },
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    debugPrint(
      'Entitlement Status Code: ${response.statusCode}',
    );

    debugPrint(
      'Entitlement Response: ${response.body}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to get entitlement status: '
        '${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }
}