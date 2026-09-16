// import 'dart:convert';
// import 'package:http/http.dart' as http;

// import '../model/PlanModel.dart';

// class PricingApiService {
//   static const String baseUrl =
//       'https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com';

//   Future<List<PlanModel>> getPlans() async {
//     final url = Uri.parse(
//       '$baseUrl/pricing/plans',
//     );

//     final response = await http.get(
//       url,
//       headers: {
//         'Content-Type': 'application/json',
//       },
//     );

//     print('Status Code: ${response.statusCode}');
//     print('Response: ${response.body}');

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data =
//           jsonDecode(response.body);

//       final List<dynamic> plansData =
//           data['plans'] ?? [];

//       return plansData.map((plan) {
//         return PlanModel.fromJson(
//           plan as Map<String, dynamic>
//         );
//       }).toList();
//     } else {
//       throw Exception(
//         'Failed to load plans: ${response.statusCode}',
//       );
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/PlanModel.dart';

class PricingApiService {
  static const String baseUrl =
      'https://8yb3c41zk8.execute-api.us-east-1.amazonaws.com';

  // =========================================================
  // GET PRICING PLANS
  // =========================================================

  Future<List<PlanModel>> getPlans() async {
    final url = Uri.parse(
      '$baseUrl/pricing/plans',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'Pricing API Status: ${response.statusCode}',
      );

      debugPrint(
        'Pricing API Response: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception(
            'Invalid pricing API response',
          );
        }

        final List<dynamic> plansData =
            decoded['plans'] ?? [];

        return plansData
            .whereType<Map<String, dynamic>>()
            .map(
              (plan) => PlanModel.fromJson(plan),
            )
            .toList();
      }

      throw Exception(
        'Failed to load plans: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint(
        'Pricing API Error: $e',
      );

      rethrow;
    }
  }
}