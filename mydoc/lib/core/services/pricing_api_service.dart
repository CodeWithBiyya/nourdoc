import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/api_envelope.dart';
import 'app_url.dart';
import '../models/PlanModel.dart';

class PricingApiService {
  static const String baseUrl =
      'https://8wfvyjajy1.execute-api.us-east-1.amazonaws.com';

  // =========================================================
  // GET PRICING PLANS
  // =========================================================

Future<List<PlanModel>> getPlans() async {
  final url = Uri.parse('$baseUrl/plans');

  try {
    debugPrint('==========================================');
    debugPrint('GET PRICING PLANS');
    debugPrint('URL: $url');
    debugPrint('==========================================');

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

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Failed to load plans: ${response.statusCode}',
      );
    }

    final dynamic decoded = unwrapApiData(jsonDecode(response.body));

    if (decoded is List) {
      final plans = decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (plan) => PlanModel.fromJson(plan),
          )
          .toList();

      debugPrint(
        'Successfully parsed ${plans.length} plans',
      );

      return plans;
    }

    throw Exception(
      'Invalid pricing API response: expected a List',
    );
  } catch (e) {
    debugPrint(
      'Pricing API Error: $e',
    );

    rethrow;
  }
}
  
}